/*  This code is based on Apple's "GeekGameBoard" sample code, version 1.0.
    http://developer.apple.com/samplecode/GeekGameBoard/
    Copyright © 2007 Apple Inc. Copyright © 2008 Jens Alfke. All Rights Reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted
    provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions
      and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials provided
      with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
    FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
    BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
    THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#import "HexchequerGame.h"
#import "HexGrid.h"
#import "Piece.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@implementation HexchequerGame


- (void) setUpBoard
{
    HexGrid *grid = [[HexGrid alloc] initWithRows: 9 columns: 9 frame: _board.bounds];
    _grid = grid;
    [_board addSublayer: _grid];
    CGPoint pos = grid.position;
    pos.x += grid.spacing.width / 4;    // The right edge of the grid is blank because of the unused cells outside the hexagon
    grid.position = pos;
    grid.allowsMoves = YES;
    grid.allowsCaptures = NO;      // no land-on captures, that is
    grid.cellColor = CreateGray(1.0, 0.25);
    grid.lineColor = kTranslucentLightGrayColor;
    [grid addCellsInHexagon];
    [_cells removeAllObjects];
    for( int y=0; y<9; y++ ) {
        for( int x=0; x<9; x++ ) {
            GridCell *cell = [_grid cellAtRow: y column: x];
            if( cell )
                [_cells addObject: cell];
        }
    }
}


- (NSString*) initialStateString
{
    return @"111111111111111111-------------------------222222222222222222";
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)srcHolder to: (id<BitHolder>)dstHolder
{
    Hex *src=(Hex*)srcHolder, *dst=(Hex*)dstHolder;
    if( [bit valueForKey: @"King"] )
        if( dst==src.bl || dst==src.br || dst==src.l || dst==src.r
           || (src.bl.bit.unfriendly && dst==src.bl.bl) || (src.br.bit.unfriendly && dst==src.br.br)
           || (src.l.bit.unfriendly  && dst==src.l.l)   || (src.r.bit.unfriendly  && dst==src.r.r) )
            return YES;    
    return dst==src.fl || dst==src.fr
        || (src.fl.bit.unfriendly && dst==src.fl.fl) || (src.fr.bit.unfriendly && dst==src.fr.fr);
}

- (void) bit: (Bit*)bit movedFrom: (id<BitHolder>)srcHolder to: (id<BitHolder>)dstHolder
{
    Hex *src=(Hex*)srcHolder, *dst=(Hex*)dstHolder;
    int playerIndex = self.currentPlayer.index;

    Turn *turn = self.currentTurn;
    if( turn.move.length==0 )
        [turn addToMove: src.name];
    [turn addToMove: @"-"];
    [turn addToMove: dst.name];
    
    BOOL isKing = ([bit valueForKey: @"King"] != nil);    
    PlaySound(isKing ?@"Funk" :@"Tink");

    // "King" a piece that made it to the last row:
    if( dst.row == (playerIndex ?0 :8) )
        if( ! isKing ) {
            PlaySound(@"Blow");
            bit.scale = 1.4;
            [bit setValue: @"King" forKey: @"King"];
            // don't set isKing flag - piece can't capture again after being kinged.
        }

    // Check for a capture:
    Hex *capture = nil;
    if(dst==src.fl.fl)
        capture = src.fl;
    else if(dst==src.fr.fr)
        capture = src.fr;
    else if(dst==src.bl.bl)
        capture = src.bl;
    else if(dst==src.br.br)
        capture = src.br;
    else if(dst==src.l.l)
        capture = src.l;
    else if(dst==src.r.r)
        capture = src.r;
    
    if( capture ) {
        PlaySound(@"Pop");
        [turn addToMove: @"!"];
        _numPieces[capture.bit.owner.index]--;
        [capture destroyBit];
        
        // Now check if another capture is possible. If so, don't end the turn:
        if( (dst.fl.bit.unfriendly && dst.fl.fl.empty) || (dst.fr.bit.unfriendly && dst.fr.fr.empty) )
            return;
        if( isKing )
            if( (dst.bl.bit.unfriendly && dst.bl.bl.empty) || (dst.br.bit.unfriendly && dst.br.br.empty)
                    || (dst.l.bit.unfriendly && dst.l.l.empty) || (dst.r.bit.unfriendly && dst.r.r.empty))
                return;
    }
    
    [self endTurn];
}


@end
