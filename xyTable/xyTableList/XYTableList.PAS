{+------------------------------------------------------------
 | Unit XYTableList
 |
 | Version: 1.0  Created: 12-3-01
 |               Last Modified: 12-3-01
 | Author : GenTypedLists Version 1.0
 | Project: General utilities
 | Description: ZERO-based list of TXYTable-items
 |
 +------------------------------------------------------------}
Unit XYTableList;
Interface

Uses Classes,
     AbstractTypedList, XYTable{, LargeArrays}, DUtils;

{.$DEFINE GTL_USEPOINTERS}
{$DEFINE GTL_USECOMPAREPROC}
{$DEFINE GTL_OWNSOBJECTS}

Type
  TxyTableSortCompare = Function( Const item1, item2: TxyTable ): Integer;

  TXYTableList = Class( TAbstractTypedList )
  Private
    Procedure Put( index: Integer; Const Item: TxyTable );
    Function  Get( index: Integer ): TxyTable;
    Procedure FreeItem( index: Integer );
    Procedure QuickSort(L, R: Integer; Compare: TxyTableSortCompare );

  Public
    Function Clone: TXYTableList;

    Procedure Assign( source: TPersistent ); override;
    Function  Add(Const Item: TxyTable): Integer;
    Procedure Insert(Index: Integer; Const Item: TxyTable);

    Procedure Clear; override;
    Procedure Delete(Index: Integer); override;
    Function  Detach(Index: Integer): TxyTable;

    Function LinearSearch( Const Item: TxyTable;
                           Compare: TxyTableSortCompare): Integer;
    Function BinarySearch( Const Item: TxyTable;
                           Compare: TxyTableSortCompare): Integer;
    Procedure Sort(Compare: TxyTableSortCompare);

    Property Items[Index: Integer]: TxyTable read Get write Put; default;
    Function DxTilNextYChange( x: Double;
             const Direction: TDirection ): Double; Virtual;
      {-Distance dx until next change in Y; =MaxDouble if no change;
        Array's must be sorted on X }
    Procedure WriteToTextFile( var f: TextFile ); Virtual;
    Function ReadXYTablesFromTextFile( var f: TextFile ): Integer; Virtual;
      {-Returns the number of tables read}
    Function SaveToStream( SaveStream: TStream ): Boolean; Virtual;
    Function LoadFromStream( LoadStream: TStream ): Boolean; Virtual;
  End;

{$IFDEF GTL_USECOMPAREPROC}
Function TxyTableCompare( Const item1, item2: TxyTable ): Integer;
{$ENDIF}

Implementation

uses
  SysUtils,
  Math,
  uError;

{$IFDEF GTL_USEPOINTERS} 
Type
    TxyTable_Ptr = ^TxyTable;
{$ENDIF}

{$IFDEF GTL_USECOMPAREPROC}
{+------------------------------------------------------------
 | Function TxyTableCompare
 |
 | Parameters :
 |   item1, item2: the two TxyTable items to compare
 | Returns    :
 |   0 if both items are equal, < 0 if item1 is smaller than item2,
 |   > 0 if item1 is larger than item2
 | Error Conditions: none
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Function TxyTableCompare( Const item1, item2: TxyTable ): Integer;
  Begin 
    {  MODIFY THIS IMPLEMENTATION AS APPROPRIATE!  }
    {If item1 < item2 Then
      Result := -1
    Else If item1 > item2 Then
      Result := 1
    Else
      Result := 0;}
    Result := -1;
  End; { TxyTableCompare }
{$ENDIF} 

{+-----------------------------
 | Methods of TXYTableList
 +----------------------------}

{+------------------------------------------------------------
 | Function TXYTableList.Clone: TXYTableList;
 |
 | Returns : a deep copy of this list instance.
 | Call method: static
 | Visibility : public
 | Description:
 |   Returns a new instance of the list class and copies the
 |   data from this list into it.
 | Error Conditions: none
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Function TXYTableList.Clone: TXYTableList;
  Begin
    Result := TXYTableList.Create;
    Result.Assign( self );
  End; { TXYTableList.Clone }

{+------------------------------------------------------------
 | Procedure TXYTableList.Assign
 |
 | Parameters :
 |   source: list instance to copy
 | Call method: virtual, overriden
 | Visibility : public
 | Description:
 |   Copies the data from the source into this instance, which
 |   is cleared first. This is a deep copy, unless the
 |   list contains a pointer type other than an object. If the
 |   list contains objects and owns
 |   the objects (GTL_OWNSOBJECTS defined) then the object 
 |   class MUST have a public Clone method, or a compiler error
 |   will result! If the list does not own the objects the copy
 |   is shallow, the new list stores references to the same objects
 |   as aList.
 | Error Conditions: 
 |   If source is not of this list class the inherited Assign is
 |   called and that will raise an exception!
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Procedure TXYTableList.Assign( source: TPersistent ); 
  Var
    i: Integer;
    aList : TXYTableList;
  Begin
    If Assigned( source ) Then Begin
      If source Is TXYTableList Then Begin 
        aList := TXYTableList( source );
        Clear;
        Capacity := aList.Count;
        For i := 0 To aList.LastIndex Do Begin 
          {$IFDEF GTL_OWNSOBJECTS}
          case aList.Items[ i ].DescendantType of
            cTxyTable: Insert( count, aList.Items[ i ].Clone( NIL ) );
            cTxyTableLinInt: Insert( count, TxyTableLinInt(aList.Items[ i ]).Clone( NIL ) );
          end; {-case}
          {$ELSE}
          Insert( count, aList.Items[ i ] );
          {$ENDIF}
        End; { For }
      End { If }
      Else
        inherited Assign( source );
    End; { If }
  End; { TXYTableList.Assign }

{+------------------------------------------------------------
 | Function TXYTableList.Add
 |
 | Parameters :
 |   Item to add. If this is a pointer type the list will store
 |   the pointer as is!
 | Returns    : the index of the item
 | Call method: static
 | Visibility : public
 | Description:
 |   Adds the passed item to the end of the list and returns the
 |   index of the item.
 | Error Conditions: 
 |   We may run out of memory here, which will cause an exception.
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Function TXYTableList.Add(Const Item: TxyTable): Integer;
  Begin
    Result := Count;
    Insert( Result, Item );
  End; { TXYTableList.Add }

{+------------------------------------------------------------
 | Procedure TXYTableList.Insert
 |
 | Parameters :
 |   Index: index of the item before which to insert the new item. 
 |          If Index >= Count the item will be appended to the list.
 |   Item : item to insert
 | Call method: static
 | Visibility : public
 | Description:
 |   Inserts the passed item into the list. If the data type is 
 |   larger than 4 bytes memory for the Item is allocated on the 
 |   heap, the item is copied into it and the pointer is stored
 |   in the list, otherwise the data is stored directly, typecast
 |   to a pointer.
 | Error Conditions:
 |   We may run out of memory here, which will cause an exception.
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Procedure TXYTableList.Insert(Index: Integer; Const Item: TxyTable);
  Begin
    If Index > Count Then
      Index := Count;
    Storage.Insert( index, Nil );
    Put( index, Item );
  End; { TXYTableList.Insert }

{+------------------------------------------------------------
 | Procedure TXYTableList.Clear
 |
 | Parameters : none
 | Call method: virtual, overriden
 | Visibility : public
 | Description:
 |   Clears the list, freeing memory for the items if necessary.
 | Error Conditions: none
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Procedure TXYTableList.Clear;
  {$IFDEF GTL_OWNSOBJECTS} {$DEFINE GTL_MUSTFREE} {$ENDIF}
  {$IFDEF GTL_USEPOINTERS} {$DEFINE GTL_MUSTFREE} {$ENDIF}
  {$IFDEF GTL_MUSTFREE}
  Var
    i: Integer;
 {$ENDIF} 
  Begin
    {$IFDEF GTL_MUSTFREE} 
      For i := LastIndex Downto 0 Do  
        FreeItem( i );
      {$UNDEF GTL_MUSTFREE }
    {$ENDIF}
    inherited Clear;
  End; { TXYTableList.Clear }

{+------------------------------------------------------------
 | Procedure TXYTableList.FreeItem
 |
 | Parameters : index of item to free
 | Call method: static
 | Visibility : private
 | Description:
 |   Frees the memory for the item at index, if required.
 | Error Conditions:
 |   A invalid index will raise a EListError exception!
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Procedure TXYTableList.FreeItem( index: Integer );
  {$IFDEF GTL_USEPOINTERS}
  Var
    pitem: TxyTable_Ptr;
  {$ENDIF}
  Begin
    {$IFDEF GTL_OWNSOBJECTS}
      Items[ Index ].Free;
    {$ELSE}
      {$IFDEF GTL_USEPOINTERS} 
        pItem := TxyTable_Ptr( Storage[ Index ] );
        If Assigned( pItem ) Then 
          Dispose( pItem );
      {$ENDIF} 
    {$ENDIF}
  End; { TXYTableList.FreeItem }

{+------------------------------------------------------------
 | Procedure TXYTableList.Delete
 |
 | Parameters :
 |   Index: index of item to delete.
 | Call method: virtual, overridden
 | Visibility : public
 | Description:
 |   Deletes the item at index from the list, freeing memory for
 |   it if necessary.
 | Error Conditions: 
 |   A invalid index will raise a EListError exception!
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Procedure TXYTableList.Delete(Index: Integer); 
  Begin
    FreeItem( Index );
    inherited Delete( Index );
  End; { TXYTableList.Delete }

{+------------------------------------------------------------
 | Function  TXYTableList.Detach
 |
 | Parameters : index of item to remove from the list
 | Returns    : the removed item
 | Call method: static
 | Visibility : public
 | Description:
 |   Returns the item at index and then deletes the entry from
 |   the list. If the list stores objects the object will of 
 |   course *not* be freed, the list relegates ownership of the
 |   data to the caller.
 | Error Conditions: 
 |   A invalid index will raise a EListError exception!
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Function  TXYTableList.Detach(Index: Integer): TxyTable; 
  Begin
    Result := Items[ Index ];
    {$IFDEF GTL_USEPOINTERS}
    Delete( index );
    {$ELSE}
    inherited Delete( index );
    {$ENDIF}
  End; { TXYTableList.Detach }

{+------------------------------------------------------------
 | Procedure TXYTableList.Put
 |
 | Property   : Items ( write )
 | Call method: static
 | Visibility : private
 | Description:
 |   Frees memory for the item at index, if required, and stores
 |   the passed item in that slot of the list. If the data type is 
 |   larger than 4 bytes memory for the Item is allocated on the 
 |   heap, the item is copied into it and the pointer is stored
 |   in the list, otherwise the data is stored directly, typecast
 |   to a pointer.
 | Error Conditions:
 |   A invalid index will raise a EListError exception!
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Procedure TXYTableList.Put( index: Integer; Const Item: TxyTable );
  {$IFDEF GTL_USEPOINTERS}
  Var
    pTemp: TxyTable_Ptr;
  {$ENDIF} 
  Begin
    FreeItem( index );
    {$IFDEF GTL_USEPOINTERS}
    New( pTemp );
    Try
      pTemp^ := Item;
      Storage.Items[ index ]:= pTemp;
    Except
      Dispose( pTemp );
      raise
    End;
    {$ELSE}
    Storage.Items[ Index ]:= Pointer( Item );
    {$ENDIF}
  End; { TXYTableList.Put }

{+------------------------------------------------------------
 | Function  TXYTableList.Get
 |
 | Property   : Items ( read )
 | Call method: static
 | Visibility : private
 | Description:
 |   Returns the item at Index in the list.
 | Error Conditions:
 |   A invalid index will raise a EListError exception!
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Function  TXYTableList.Get( index: Integer ): TxyTable;
  Begin
    {$IFDEF GTL_USEPOINTERS} 
    Result := TxyTable_Ptr( Storage.Items[ index ] )^
    {$ELSE}
    Result := TxyTable( Storage.Items[ index ] );
    {$ENDIF}
  End; { TXYTableList.Get }

{+------------------------------------------------------------
 | Function TXYTableList.LinearSearch
 |
 | Parameters :
 |   Item: item to search for
 |   Compare: compare method to use
 | Returns    : the index of the item, or -1, if the item is not
 |              found.
 | Call method: static
 | Visibility : public
 | Description:
 |   Performs a linear search over the list and stops at the first
 |   item that matches the passed one.
 | Error Conditions: none
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Function TXYTableList.LinearSearch( Const Item: TxyTable;
                       Compare: TxyTableSortCompare): Integer;
  Var
    i: Integer;
  Begin
    Assert( Assigned( Compare ));
    Result := -1;
    For i := 0 To LastIndex Do Begin
      If Compare( Item, Items[ i ] ) = 0 Then Begin
        Result := i;
        Break;
      End; { If }
    End; { For }
  End; { TXYTableList.LinearSearch }

{+------------------------------------------------------------
 | Function TXYTableList.BinarySearch
 |
 | Parameters :
 |   Item: item to search for
 |   Compare: compare method to use
 | Returns    : the index of the item, or -1, if the item is not
 |              found.
 | Call method: static
 | Visibility : public
 | Description:
 |   Performs a binary search over the list and stops at the first
 |   item that matches the passed one. The list needs to be sorted
 |   for this kind of find to work and the same Compare function
 |   needs to be used for sort and search! If the list contains duplicate 
 |   items binary search will find one of them but not necessarily 
 |   the first!
 |   The implementation has not been optimized for speed in any way!
 | Error Conditions: none
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Function TXYTableList.BinarySearch( Const Item: TxyTable; 
                       Compare: TxyTableSortCompare): Integer;
  Var
    first, last, pivot, res: Integer;
  Begin
    Assert( Assigned( Compare ));
    Result := -1;
    If count = 0 Then Exit;

    first := 0;
    last  := LastIndex;
    Repeat
      pivot := ( first + last ) div 2;
      res := Compare( Item, Items[ pivot ] );
      If res = 0 Then Begin 
        { Found the item, return its index and exit. }
        Result := pivot;
        Break;
      End { If }
      Else If res > 0 Then Begin 
        { Item is larger than item at pivot }
        first := pivot + 1;
      End { If }
      Else Begin 
        { Item is smaller than item at pivot } 
        last := pivot - 1;
      End;
    Until last < first;
  End; { TXYTableList.BinarySearch }

Procedure TXYTableList.QuickSort(L, R: Integer; Compare: TxyTableSortCompare );
  Var
    I, J: Integer;
    P: TxyTable;
  Begin
    Repeat
      I := L;
      J := R;
      P := Items[(L + R) shr 1];
      Repeat
        While Compare(Items[I], P) < 0 Do Inc(I);
        While Compare(Items[J], P) > 0 Do Dec(J);
        If I <= J Then
        Begin
          Exchange( I, J );
          Inc(I);
          Dec(J);
        End;
      Until I > J;
      If L < J Then QuickSort(L, J, Compare);
      L := I;
    Until I >= R;
  End; { TXYTableList.QuickSort }

{+------------------------------------------------------------
 | Procedure TXYTableList.Sort
 |
 | Parameters : function to use to compare items
 | Call method: static
 | Visibility : public
 | Description:
 |   Performs a quicksort on the list. The sort code is modified
 |   from TList.Sort.
 | Error Conditions: none
 | Created: 12-3-01 by GenTypedLists Version 1.0
 +------------------------------------------------------------}
Procedure TXYTableList.Sort(Compare: TxyTableSortCompare);
  Begin
    Assert( Assigned( Compare ));
    If Count > 1 Then
      QuickSort(0, LastIndex, Compare);
  End; { TXYTableList.Sort }

Function TXYTableList.DxTilNextYChange( x: Double;
         const Direction: TDirection ): Double;
var
  i: Integer;
begin
  if ( Direction = FrWrd ) then begin
    Result := MaxSingle;
    for i:=0 to Count-1 do
      Result := Min( Result, Items[ i ].DxTilNextYChange( x, Direction ) );
  end else begin
    Result := -MaxSingle;
    for i:=0 to Count-1 do
      Result := Max( Result, Items[ i ].DxTilNextYChange( x, Direction ) );
  end;
end;

Function TXYTableList.ReadXYTablesFromTextFile( var f: TextFile ): Integer;
var
  NrOfxyTables, i, iTableType, InitialCount: Integer;
begin
  WriteToLogFile( 'TXYTableList: Reading TxyTables (or descendants) from text-file.' );
  InitialCount := Count;
  Try
    Readln( f, NrOfxyTables );
    WriteToLogFile( format( 'NrOfxyTables= %d', [NrOfxyTables] ) );
    for i:=0 to NrOfxyTables-1 do begin
      Readln( f, iTableType );
      case iTableType of
        Ord( cTxyTable ): begin
             WriteToLogFile( Format( 'Reading xyTable %d of type: TxyTable.', [i+1] ) );
             Add( TxyTable.InitialiseFromTextFile( f, nil ) );
           end;
        Ord( cTxyTableLinInt ): begin
             WriteToLogFile( Format( 'Reading xyTable %d of type: TxyTableLinInt.', [i+1] ) );
             Add( TxyTableLinInt.InitialiseFromTextFile( f, nil ) );
           end;
      else
        WriteToLogFile( Format( 'Unknown table type: %d', [iTableType] ) );
        raise Exception.Create( 'Unknown table type ' +
                            '"in TXYTableList.ReadXYTablesFromTextFile".' )
      end;
    end;
  Except
    On E: Exception do
      WriteToLogFile( E.Message );
  end;
  Result := ( Count - InitialCount );
end;

Procedure TXYTableList.WriteToTextFile( var f: TextFile );
var
  i: Integer;
begin
  Writeln( f, Count ); {=NrOfDoubleMatrices}
  for i:=0 to LastIndex do begin
    Writeln( f, Ord( Items[ i ].DescendantType ) );
    Items[ i ].WriteToTextFile( f );
  end;
end;

Function TXYTableList.SaveToStream( SaveStream: TStream ): Boolean;
var
  i, n: Integer;
begin
  Result := true;
  Try
    n := Count;
    SaveStream.WriteData( n, Sizeof( Integer ) ); {=NrOfXYMatrices}
    i := 0;
    while Result and ( i <= LastIndex ) do begin
      SaveStream.WriteData(  Integer( Items[ i ].DescendantType ), SizeOf( Integer ) );
      Result := Items[ i ].SaveToStream( SaveStream );
      Inc( i );
    end; {-for i}
  Except
    Result := false;
  End;
end;

Function TXYTableList.LoadFromStream( LoadStream: TStream ): Boolean;
var
  NrOfxyTables, i, iTableType, InitialCount: Integer;
begin
  Result := true;
  Try
    clear;
    LoadStream.ReadData( NrOfxyTables, SizeOf( Integer ) );
    i := 0;
    while Result and ( i <= NrOfxyTables-1 ) do begin
      LoadStream.ReadData( iTableType, SizeOf( Integer ) );
      case iTableType of
        Ord( cTxyTable ): Add( TxyTable.Create( 0, nil ) );
        Ord( cTxyTableLinInt ): Add( TxyTableLinInt.Create( 0, nil ));
      else
        raise Exception.Create( 'Unknown table type ' +
                            '"in TXYTableList.ReadXYTablesFromTextFile".' )
      end;
      Result := Items[ i ].LoadFromStream( LoadStream );
      Inc( i );
    end; {-for}
  Except
    Result := false;
  end;
end;

Initialization
  with FormatSettings do begin {-Delphi XE6}
    DecimalSeparator := '.';
  end;
End  {XYTableList }.

