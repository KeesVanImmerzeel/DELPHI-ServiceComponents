unit uTriwacoGrid;

interface

uses SysUtils, Classes, uPlane, AdoSets, LargeArrays;

type
  PtriwacoGrid = ^TtriwacoGrid;
  TtriwacoGrid = Class( TComponent )
  private
    CoEP: Array of TPlaneCoefficients; // CoefficientsOfElementPlanes
    Procedure FreeAllMemory( const Error: Boolean ); Virtual;
    Procedure WriteHeadingInfo( var f: TextFile ); Virtual;
    Procedure ExportRiversToOpenedUngFile( var f: TextFile ); Virtual;
    Destructor  Destroy; Override;
  public
    NrOfNodes,
    NrOfElements,
    NrOfFixedPoints,
    NrOfSources,
    NrOfRivers,
    NrOfRiverNodes,
    NrOfBoundaryNodes: Integer;
    XcoordinatesNodes, YcoordinatesNodes, ElementArea,
    NodeInfluenceArea, BoundarySegments: TRealAdoSet;
    ElementNodes1, ElementNodes2, ElementNodes3,
    SourceNodes, ListBoundaryNodes,
    NrOfNodesPerRiver, ListRiverNodes,
    SourceNumber, RiverNumber: TIntegerAdoSet;
    YNIsLinkedRiverNodeArray: TLargeIntegerArray;
    Procedure   ExportToOpenedTextFile( var f: TextFile );
    Constructor InitFromOpenedTextFile( var f: TextFile;
                AOwner: TComponent; var LineNr: LongWord;
                var Initiated: Boolean );

    Constructor InitFromTextFile( const FileName: String;
                AOwner: TComponent; var Initiated: Boolean );
    Function XcoordinateSourceNode( const i: Integer ): Double; Virtual;
    Function YcoordinateSourceNode( const i: Integer ): Double; Virtual;
    Function XcoordinateRiverNode( const i: Integer ): Double; Virtual;
    Function YcoordinateRiverNode( const i: Integer ): Double; Virtual;
    Function XcoordinateBoundaryNode( const i: Integer ): Double; Virtual;
    Function YcoordinateBoundaryNode( const i: Integer ): Double; Virtual;
    Function CoordinatesOfElementNodes( const ElementNr: Integer ): T2dTriangle; Virtual;
    Function GetDistanceFromNode( const i: Integer; const x, y: Double ): Double; Virtual;
    Function GetClosestNode( const x, y: Double ): Integer; Virtual;
    Procedure GetClosest3Nodes( const x, y: Double; var nod1, nod2, nod3: integer; var dist1, dist2, dist3: Double ); Virtual;
     {-dist1 <= dist2 <= dist 3!}
    Procedure Get3WeightsForIDWInterpolation( const dist1, dist2, dist3: Double; var w1, w2, w3: Double ); Virtual;
    Function EstimateValueInNode( const x, y: Double; const aRealAdoSet: TRealAdoSet; var ValueInNode: Double ): Boolean; Virtual;
    Function GetRiverID( const RiverNodeNr: Integer ): Integer; Virtual;
    Procedure ExportLinkedNodeUngFile( const UngFileName: String; const aRealAdoSet: TRealAdoSet; var lf: TextFile );
    Procedure SetYNIsLinkedRiverNodeArray( const aRealAdoSet: TRealAdoSet ); Virtual;
    Function ExportToPEST( const aRealAdoSet: TRealAdoSet; const aAdoSetType: Integer;
      const iFileName: TFileName ): Integer;
    Function PrepareForLinearInterpolationOnElements( ValuesAtNodes: TRealAdoSet ): Boolean; Virtual;
    // Werkt alleen als 'PrepareForLinearInterpolationOnElements'
    // eerst is geinitieerd.
    Function GetInterpolatedValue( ElementNr: Integer; ExactLocation: T2dPoint ): Double; Virtual;
  end;

Type
  ENrOfRivNodesDoesNotMatchNrOfElementsInAdoSet = class( Exception );

ResourceString
  sNrOfRivNodesDoesNotMatchNrOfElementsInAdoSet = 'Nr. of river nodes does not match nr of elements in Adoset [%s].';

procedure Register;

implementation

uses
  Dialogs,
  uError, OpWstring, Math;

Function TtriwacoGrid.PrepareForLinearInterpolationOnElements( ValuesAtNodes: TRealAdoSet ): Boolean;
var
  i, nodenr1, nodenr2, nodenr3: Integer;
  P, Q, R: T3dPoint;
  {Pln_Coeff: TPlaneCoefficients;}
begin
  Result := false;
  try
  try
    if ValuesAtNodes.NrOfElements <> NrOfNodes then
      raise Exception.Create('Ado set does not comply with triwaco grid.');
    SetLength( CoEP, NrOfElements );
    for i:=1 to NrOfElements do begin
      NodeNr1 := ElementNodes1[ i ];
      NodeNr2 := ElementNodes2[ i ];
      NodeNr3 := ElementNodes3[ i ];

      P.X     := XcoordinatesNodes[ NodeNr1 ];
      P.Y     := YcoordinatesNodes[ NodeNr1 ];
      P.Z     := ValuesAtNodes[ NodeNr1 ];

      Q.X     := XcoordinatesNodes[ NodeNr2 ];
      Q.Y     := YcoordinatesNodes[ NodeNr2 ];
      Q.Z     := ValuesAtNodes[ NodeNr2 ];

      R.X     := XcoordinatesNodes[ NodeNr3];
      R.Y     := YcoordinatesNodes[ NodeNr3 ];
      R.Z     := ValuesAtNodes[ NodeNr3 ];

      CoEP[ i-1 ] := CoefficientsOfPlane( P, Q, R );

    end;
    Result := true;
  except
    On E: Exception do
      HandleError( E.Message, true );
  end;
  finally
  end;
end;

Function TtriwacoGrid.GetInterpolatedValue( ElementNr: Integer;
  ExactLocation: T2dPoint ): Double;
begin
  Result := GetValueAt( ExactLocation, CoEP[ ElementNr-1 ] );
end;

Function TtriwacoGrid.CoordinatesOfElementNodes( const ElementNr: Integer ): T2dTriangle;
var
  NodeNr: Integer;
begin
  NodeNr := ElementNodes1[ ElementNr ];
  Result.P1.X := XcoordinatesNodes[ NodeNr ];
  Result.P1.Y := YcoordinatesNodes[ NodeNr ];
  NodeNr := ElementNodes2[ ElementNr ];
  Result.P2.X := XcoordinatesNodes[ NodeNr ];
  Result.P2.Y := YcoordinatesNodes[ NodeNr ];
  NodeNr := ElementNodes3[ ElementNr ];
  Result.P3.X := XcoordinatesNodes[ NodeNr ];
  Result.P3.Y := YcoordinatesNodes[ NodeNr ];
end;

Procedure TtriwacoGrid.SetYNIsLinkedRiverNodeArray( const aRealAdoSet: TRealAdoSet );
var
  i, j, m, RivNodeSum, RiverNr: integer;
  PrevValue, NextValue: Double;
  Jump: Boolean;
begin
  RivNodeSum := 0;

  for RiverNr:=1 to NrOfRivers do begin
    m := NrOfNodesPerRiver[ RiverNr ];
    {-if all values are the same, choose the middle river node}
    j := RivNodeSum + 1;
    PrevValue := aRealAdoSet[ j ]; Jump := false; i := 2;
    while ( not Jump ) and ( i <= m ) do begin
      j := RivNodeSum + i;
      NextValue := aRealAdoSet[ j ];
      Jump := ( NextValue <> PrevValue );
      Inc( i ); PrevValue := NextValue;
    end;
    if ( not Jump ) then begin
      if ( m > 1 ) then
        j := RivNodeSum + ( m div 2 )
      else
        j := RivNodeSum + 1;
      YNIsLinkedRiverNodeArray[ j ] := 1;
    end else begin
      {-Not all values are the same}
      j := RivNodeSum + 1;
      YNIsLinkedRiverNodeArray[ j ] := 1; {-First river node is always linked point}
      PrevValue := aRealAdoSet[ j ];
      for i:=2 to m-1 do begin
        j := RivNodeSum + i;
        NextValue := aRealAdoSet[ j ];
        if ( NextValue <> PrevValue ) then begin
          YNIsLinkedRiverNodeArray[ j-1 ] := 1;
          YNIsLinkedRiverNodeArray[ j ] := 1;
        end;
        PrevValue := NextValue;
      end;
      j := RivNodeSum + m;
      YNIsLinkedRiverNodeArray[ j ] := 1; {-Last river node is always linked point}
    end;
    RivNodeSum := RivNodeSum + m;
  end; {-for RiverNr}
end; {-Procedure SetYNIsLinkedRiverNodeArray}

Function TtriwacoGrid.ExportToPEST( const aRealAdoSet: TRealAdoSet; const aAdoSetType: Integer;
      const iFileName: TFileName ): Integer;
var
  i: Integer;
  f: TextFile;
  sx, sy, sz: String;
begin
  WriteToLogFileFmt( 'Adoset [%s] ExportToPEST [%s].', [aRealAdoSet.SetIdStr,
    ExpandFileName( iFileName )] );
  Result := cUnknownError;
  Try Try
    AssignFile( f, iFileName ); Rewrite( f );
    Writeln( f, Format( '%9s %19s %19s %19s', ['nr', 'x', 'y', aRealAdoSet.SetIdStr ] ) );
    case aAdoSetType of
      cNODE: begin
        for i := 1 to NrOfNodes do begin
          sx := GetAdoGetal( XcoordinatesNodes[ i ] );
          sy := GetAdoGetal( YcoordinatesNodes[ i ] );
          sz := GetAdoGetal( aRealAdoSet[ i ] );
          Writeln( f, format( '%9d %19s %19s %19s', [ i, sx, sy, sz ] ) );
        end;
      end;
      cSOURCE: begin
        for i := 1 to NrOfSources do begin
          sx := GetAdoGetal( XcoordinateSourceNode( i ) );
          sy := GetAdoGetal( YcoordinateSourceNode( i ) );
          sz := GetAdoGetal( aRealAdoSet[ i ] );
          Writeln( f, format( '%9d %19s %19s %19s', [ i, sx, sy, sz ] ) );
        end;
      end;
      cBOUNDARY: begin
        for i := 1 to NrOfBoundaryNodes do begin
          sx := GetAdoGetal( XcoordinateBoundaryNode( i ) );
          sy := GetAdoGetal( YcoordinateBoundaryNode( i ) );
          sz := GetAdoGetal( aRealAdoSet[ i ] );
          Writeln( f, format( '%9d %19s %19s %19s', [ i, sx, sy, sz ] ) );
        end;
      end;
      cRIVER: begin
        for i := 1 to NrOfRiverNodes do begin
          sx := GetAdoGetal( XcoordinateRiverNode( i ) );
          sy := GetAdoGetal( YcoordinateRiverNode( i ) );
          sz := GetAdoGetal( aRealAdoSet[ i ] );
          Writeln( f, format( '%9d %19s %19s %19s', [ i, sx, sy, sz ] ) );
        end;
      end;
      else Raise Exception.CreateFmt( 'Invalid AdoSet type %d', [aAdoSetType] );
    end;
    Result := cNoError
    Except
      On E: Exception do
        WriteToLogFile( E.Message );
    end
  Finally
    Try CloseFile( f ); except end;
  end;
end;

Procedure TtriwacoGrid.ExportLinkedNodeUngFile( const UngFileName: String; const aRealAdoSet: TRealAdoSet; var lf: TextFile );
var
  i, n: Integer;
  f: TextFile;
begin
  Try Try
    n := aRealAdoSet.NrOfElements;
    if ( n <> NrOfRiverNodes ) then
      Raise ENrOfRivNodesDoesNotMatchNrOfElementsInAdoSet.CreateResFmt( @sNrOfRivNodesDoesNotMatchNrOfElementsInAdoSet,
        [aRealAdoSet.SetIdStr] );
    AssignFile( f, UngFileName ); Rewrite( f );
    {-Maak linked node file}
    SetYNIsLinkedRiverNodeArray( aRealAdoSet );
    ExportRiversToOpenedUngFile( f );
    for i:=1 to n do begin
      if ( YNIsLinkedRiverNodeArray[ i ] <> 0 ) then begin {-Is linked node}
        Writeln( f, GetRiverID( i ):8, ' ',
                    XcoordinateRiverNode( i ):10:2, ' ', YcoordinateRiverNode( i ):10:2, ' ',
                    aRealAdoSet[ i ]:10:2 );
      end; {-if}
    end; {-for}
    Writeln( f, 'END' );
    CloseFile( f );
  Except
    On E: Exception do begin
        HandleError(  E.Message, false );
      end;
  end; {-Except}
  Finally
  end; {-Finally}
end;

Function TtriwacoGrid.GetRiverID( const RiverNodeNr: Integer ): Integer;
var
  RivNodeSum, RiverNr: Integer;
begin
  Result := -1;
  if ( RiverNodeNr > 0 ) and ( RiverNodeNr <= NrOfRiverNodes ) then begin
    {Bepaal rivernumber}
    RiverNr := 0; RivNodeSum := 0;
    repeat
      Inc( RiverNr );
      RivNodeSum := RivNodeSum + NrOfNodesPerRiver[ RiverNr ] ;
    until ( ( RiverNodeNr <= RivNodeSum ) or ( RiverNr = NrOfRivers ) );
    {Bepaal op basis van rivernumber de RiverID}
    Result := RiverNumber[ RiverNr ];
  end;
end;

Procedure TtriwacoGrid.WriteHeadingInfo( var f: TextFile );
begin
  Writeln( f, 'NUMBER NODES          = ', NrOfNodes );
  WriteToLogFile( Format( 'NUMBER NODES          = %d', [NrOfNodes] ) );
  Writeln( f, 'NUMBER ELEMENTS       = ', NrOfElements );
  WriteToLogFile( Format( 'NUMBER ELEMENTS       = %d', [NrOfElements] ) );
  Writeln( f, 'NUMBER FIXED POINTS   = ', NrOfFixedPoints );
  WriteToLogFile( Format( 'NUMBER FIXED POINTS   = %d', [NrOfFixedPoints] ) );
  Writeln( f, 'NUMBER SOURCES        = ', NrOfSources );
  WriteToLogFile( Format( 'NUMBER SOURCES        = %d', [NrOfSources] ) );
  Writeln( f, 'NUMBER RIVERS         = ', NrOfRivers );
  WriteToLogFile( Format( 'NUMBER RIVERS         = %d', [NrOfRivers] ) );
  Writeln( f, 'NUMBER RIVER NODES    = ', NrOfRiverNodes );
  WriteToLogFile( Format( 'NUMBER RIVER NODES    = %d', [NrOfRiverNodes] ) );
  Writeln( f, 'NUMBER BOUNDARY NODES = ', NrOfBoundaryNodes );
  WriteToLogFile( Format( 'NUMBER BOUNDARY NODES = %d', [NrOfBoundaryNodes] ) );
end;

Function TtriwacoGrid.GetDistanceFromNode( const i: Integer; const x, y: Double ): Double;
begin
  Result := Sqrt( Sqr( x - XcoordinatesNodes[i] ) +  Sqr( y - YcoordinatesNodes[i] ) );
end;

Function TtriwacoGrid.GetClosestNode( const x, y: Double ): Integer;
var
  i, n: Integer;
  Dist, aDist: Double;
begin
  Dist := GetDistanceFromNode( 1, x, y );
  Result := 1;
  n := NrOfNodes;
  for i:=2 to n do begin
    aDist := GetDistanceFromNode( i, x, y );
    if ( aDist < Dist ) then begin
      Result := i;
      Dist := aDist;
    end;
  end;
end;

Procedure TtriwacoGrid.GetClosest3Nodes( const x, y: Double; var nod1, nod2, nod3: integer; var dist1, dist2, dist3: Double );
var
  i, n: Integer;
  aDist: Double;
begin
  Dist1 := GetDistanceFromNode( 1, x, y );
  Dist2 := Dist1; Dist3 := Dist1;
  n := NrOfNodes;
  for i:=2 to n do begin
    aDist := GetDistanceFromNode( i, x, y );
    if ( aDist < Dist1 ) then begin {#3 wordt #2; #2 wordt #1; #1 wordt nieuw}
      Dist3 := Dist2; nod3 := nod2;
      Dist2 := Dist1; nod2 := nod1;
      Dist1 := aDist; nod1 := i;
    end else if ( aDist < Dist2 ) then begin {#1 & #3 blijven hetzelfde; #2 nieuw}
      Dist2 := aDist; nod2 := i;
    end else if ( aDist < Dist3 ) then begin {#1 & #2 blijven hetzelfde; #3 nieuw}
      Dist3 := aDist; nod3 := i;
    end; {-if}
  end; {-for}
end;

Procedure TtriwacoGrid.Get3WeightsForIDWInterpolation( const dist1, dist2, dist3: Double; var w1, w2, w3: Double );
const
  VerySmallDistance = 1;
var
  wDist: Double;
begin
  if ( dist1 < VerySmallDistance ) then begin
    w1 := 1; w2 := 0; w3 := 0;
  end else begin
    wDist := 1 / ( ( 1 / dist1 ) + ( 1 / dist2 ) + ( 1/ dist3 ) );
    w1 := wDist / dist1;
    w2 := wDist / dist2;
    w3 := wDist / dist3;
  end;
end;

Function TtriwacoGrid.EstimateValueInNode( const x, y: Double; const aRealAdoSet: TRealAdoSet; var ValueInNode: Double ): Boolean;
var
  nod1, nod2, nod3: integer;
  dist1, dist2, dist3, w1, w2, w3: Double;
begin
  Result := false;
  Try
    if ( NrOfNodes <> aRealAdoSet.NrOfElements ) then
      raise Exception.Create( 'Real ado set does not match grid file' );
    GetClosest3Nodes( x, y, nod1, nod2, nod3, dist1, dist2, dist3 );
    Get3WeightsForIDWInterpolation( dist1, dist2, dist3, w1, w2, w3 );
    ValueInNode :=  w1 * aRealAdoSet[ nod1 ] + w2 * aRealAdoSet[ nod2 ] + w3 * aRealAdoSet[ nod3 ];
  except
    Result := false;
  end;
end;

procedure TtriwacoGrid.ExportToOpenedTextFile( var f: TextFile );
begin
  //WriteToLogFileFmt( 'Exporting Triwaco grid to TextFile.' );
  WriteToLogFile( 'Exporting Triwaco grid to TextFile.' );

  WriteHeadingInfo( f );
  XcoordinatesNodes.ExportToOpenedTextFile( f );
  YcoordinatesNodes.ExportToOpenedTextFile( f );
  ElementNodes1.ExportToOpenedTextFile( f );
  ElementNodes2.ExportToOpenedTextFile( f );
  ElementNodes3.ExportToOpenedTextFile( f );
  ElementArea.ExportToOpenedTextFile( f );
  NodeInfluenceArea.ExportToOpenedTextFile( f );
  if ( NrOfSources > 0 ) then
  SourceNodes.ExportToOpenedTextFile( f );
  if ( NrOfRivers > 0 ) then begin
    NrOfNodesPerRiver.ExportToOpenedTextFile( f );
    ListRiverNodes.ExportToOpenedTextFile( f );
  end;
  ListBoundaryNodes.ExportToOpenedTextFile( f );
  BoundarySegments.ExportToOpenedTextFile( f );
  if ( NrOfSources > 0 ) then
    SourceNumber.ExportToOpenedTextFile( f );
  if ( NrOfRivers > 0 ) then
    RiverNumber.ExportToOpenedTextFile( f );
  Writeln( f, 'END FILE GRIDFL' );
end;

constructor TtriwacoGrid.InitFromOpenedTextFile( var f: TextFile;
                AOwner: TComponent; var LineNr: LongWord;
                var Initiated: Boolean );
const
  WordDelims: CharSet = ['='];
var
  S: String;
  Len: Integer;
  SubSetInitiated: Boolean;
begin
  Initiated := False;
  SetLength( CoEP, 0 );

  {-Read heading-info}
  NrOfNodes         := 0;
  NrOfElements      := 0;
  NrOfFixedPoints   := 0;
  NrOfSources       := 0;
  NrOfRivers        := 0;
  NrOfRiverNodes    := 0;
  NrOfBoundaryNodes := 0;
  LineNr            := 1;
  try
    Readln( f );    Inc( LineNr );
    Readln( f, S ); Inc( LineNr ); NrOfNodes := StrToInt( Trim( ExtractWord( 2, S, WordDelims, Len ) ) );
    If ( NrOfNodes <= 0 ) then Exit;
    Readln( f, S ); Inc( LineNr ); NrOfElements := StrToInt( Trim( ExtractWord( 2, S, WordDelims, Len ) ) );
    If ( NrOfElements <= 0 ) then Exit;
    Readln( f, S ); Inc( LineNr ); NrOfFixedPoints := StrToInt( Trim( ExtractWord( 2, S, WordDelims, Len ) ) );
    If ( NrOfFixedPoints < 0 ) then Exit;
    Readln( f, S ); Inc( LineNr ); NrOfSources := StrToInt( Trim( ExtractWord( 2, S, WordDelims, Len ) ) );
    If ( NrOfSources < 0 ) then Exit;
    Readln( f, S ); Inc( LineNr ); NrOfRivers := StrToInt( Trim( ExtractWord( 2, S, WordDelims, Len ) ) );
    If ( NrOfRivers < 0 ) then Exit;
    Readln( f, S ); Inc( LineNr ); NrOfRiverNodes := StrToInt( Trim( ExtractWord( 2, S, WordDelims, Len ) ) );
    If ( ( NrOfRivers > 0 ) and ( NrOfRiverNodes <=0 ) ) or ( NrOfRiverNodes <0 )
      then Exit;
    Readln( f, S ); Inc( LineNr ); NrOfBoundaryNodes := StrToInt( Trim( ExtractWord( 2, S, WordDelims, Len ) ) );
    If ( NrOfBoundaryNodes <= 0 ) then Exit;
    //WriteHeadingInfo;
  except
    HandleError( 'Error reading heading of Triwaco grid file.', false ); Exit;
  end;

  {-Read x, y-coordinates}
  XcoordinatesNodes := TRealAdoSet.InitFromOpenedTextFile( f, 'X-COORDINATES NODES=', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( XcoordinatesNodes.NrOfElements <> NrOfNodes )
   then begin
    HandleError (  'Error reading set "X-COORDINATES NODES=" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;
  YcoordinatesNodes := TRealAdoSet.InitFromOpenedTextFile( f, 'Y-COORDINATES NODES=', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( YcoordinatesNodes.NrOfElements <> NrOfNodes )
   then begin
    HandleError( 'Error reading set "Y-COORDINATES NODES=" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;

  {-Read Node numbers of elements}
  ElementNodes1 := TIntegerAdoSet.InitFromOpenedTextFile( f, 'ELEMENT NODES 1=====', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( ElementNodes1.NrOfElements <> NrOfElements )
   then begin
    if( not SubSetInitiated ) then WriteToLogFile( 'not SubSetInitiated' ) //WriteToLogFileFmt( 'not SubSetInitiated' )
    else
      WriteToLogFile( Format( 'ElementNodes1.NrOfElements = %d; NrOfElements= ', [ElementNodes1.NrOfElements, NrOfElements] ) );
    HandleError( 'Error reading set "ELEMENT NODES 1=====" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;
  ElementNodes2 := TIntegerAdoSet.InitFromOpenedTextFile( f, 'ELEMENT NODES 2=====', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( ElementNodes2.NrOfElements <> NrOfElements )
   then begin
    HandleError( 'Error reading set "ELEMENT NODES 2=====" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;
  ElementNodes3 := TIntegerAdoSet.InitFromOpenedTextFile( f, 'ELEMENT NODES 3=====', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( ElementNodes3.NrOfElements <> NrOfElements )
   then begin
    HandleError( 'Error reading set "ELEMENT NODES 3=====" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;

  {-Read area of elements}
  ElementArea := TRealAdoSet.InitFromOpenedTextFile( f, 'ELEMENT AREA========', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( ( ElementArea.NrOfElements <> NrOfElements )  and
    (ElementArea.NrOfElements <> 1) )
   then begin
    HandleError( 'Error reading set "ELEMENT AREA========" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;

  {-Read influence area of nodes}
  NodeInfluenceArea := TRealAdoSet.InitFromOpenedTextFile( f, 'NODE INFLUENCE AREA=', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( NodeInfluenceArea.NrOfElements <> NrOfNodes )
   then begin
    HandleError( 'Error reading set "NODE INFLUENCE AREA=" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;

  if ( NrOfSources > 0 ) then begin
    {-Read source nodes}
    SourceNodes := TIntegerAdoSet.InitFromOpenedTextFile( f, 'SOURCE NODES========', AOwner, LineNr, SubSetInitiated );
    if ( not SubSetInitiated ) or ( SourceNodes.NrOfElements <> NrOfSources ) then begin
        HandleError( 'Error reading set "SOURCE NODES========" from Triwaco grid file.', false );
        FreeAllMemory( true );
        Exit;
    end;
  end;

  if ( NrOfRivers > 0 ) then begin
    {-Read nr. of nodes per river}
    NrOfNodesPerRiver := TIntegerAdoSet.InitFromOpenedTextFile( f, 'NUMBER NODES/RIVER==', AOwner, LineNr, SubSetInitiated );
    if ( not SubSetInitiated ) or ( NrOfNodesPerRiver.NrOfElements <> NrOfRivers ) then begin
        HandleError( 'Error reading set "NUMBER NODES/RIVER==" from Triwaco grid file.', false );
        FreeAllMemory( true );
        Exit;
    end;

    {-Read LIST RIVER NODES====}
    ListRiverNodes := TIntegerAdoSet.InitFromOpenedTextFile( f, 'LIST RIVER NODES====', AOwner, LineNr, SubSetInitiated );
    if ( not SubSetInitiated ) or ( ListRiverNodes.NrOfElements <> NrOfRiverNodes ) then begin
        HandleError( 'Error reading set "LIST RIVER NODES====" from Triwaco grid file.', false );
        FreeAllMemory( true );
        Exit;
    end;
    YNIsLinkedRiverNodeArray := TLargeIntegerArray.CreateF( NrOfRiverNodes, 0, self );
  end;

  {-Read boundary nodes}
  ListBoundaryNodes := TIntegerAdoSet.InitFromOpenedTextFile( f, 'LIST BOUNDARY NODES=', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( ListBoundaryNodes.NrOfElements <> NrOfBoundaryNodes )
   then begin
    HandleError( 'Error reading set "LIST BOUNDARY NODES=" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;

  {-Read boundary segments}
  BoundarySegments := TRealAdoSet.InitFromOpenedTextFile( f, 'BOUNDARY SEGMENTS===', AOwner, LineNr, SubSetInitiated );
  if ( not SubSetInitiated ) or ( BoundarySegments.NrOfElements <> NrOfBoundaryNodes )
   then begin
    HandleError( 'Error reading set "BOUNDARY SEGMENTS===" from Triwaco grid file.', false );
    FreeAllMemory( true );
    Exit;
  end;

  {-Read source numbers}
  if ( NrOfSources > 0 ) then begin
    SourceNumber := TIntegerAdoSet.InitFromOpenedTextFile( f, 'SOURCENUMBER', AOwner, LineNr, SubSetInitiated );
    if ( not SubSetInitiated ) or ( SourceNumber.NrOfElements <> NrOfSources )
     then {begin
      WriteToLogFileFmt( 'Error reading set "SOURCENUMBER" from Triwaco grid file.' );
      FreeAllMemory( true );
      Exit;
    end};
  end;

  if ( NrOfRivers > 0 ) then begin
    {-Read river numbers}
    RiverNumber := TIntegerAdoSet.InitFromOpenedTextFile( f, 'RIVERNUMBER', AOwner, LineNr, SubSetInitiated );
    if ( not SubSetInitiated ) or ( RiverNumber.NrOfElements <> NrOfRivers ) then {begin
      WriteToLogFileFmt( 'Error reading set "RIVERNUMBER" from Triwaco grid file.' );
      FreeAllMemory( true );
      Exit;
    end};
  end;

  Initiated := true;

end;

Constructor TtriwacoGrid.InitFromTextFile( const FileName: String;
                AOwner: TComponent; var Initiated: Boolean );
var
  LineNr: LongWord;
  f: TextFile;
begin
  try
    AssignFile( f, FileName ); Reset( f );
    LineNr := 0;
    InitFromOpenedTextFile( f, AOwner, LineNr, Initiated );
    CloseFile( f );
    if not Initiated then
      Raise Exception.Create( 'Could not initiate Triwaco Grid' );
  except
    On E: Exception do begin
      HandleError(  E.Message, false );
      {MessageBeep( MB_ICONASTERISK );}
    end;
  end;
end;

Procedure TtriwacoGrid.FreeAllMemory( const Error: Boolean );
begin
  try
    SetLength( CoEP, 0 );
    XcoordinatesNodes.free;
    YcoordinatesNodes.free;
    ElementNodes1.free;
    ElementNodes2.free;
    ElementNodes3.free;
    ElementArea.free;
    NodeInfluenceArea.free;
    SourceNodes.free;
    NrOfNodesPerRiver.free;
    ListRiverNodes.free;
    ListBoundaryNodes.free;
    BoundarySegments.free;
    SourceNumber.free;
    RiverNumber.free;
    YNIsLinkedRiverNodeArray.Free;
  except
  end;
  if Error then begin
    MessageDlg( 'Error reading Triwaco grid file. Check log file.', mtError, [mbOk], 0);
  end;
end;

Destructor TtriwacoGrid.Destroy;
begin
  FreeAllMemory( false );
  Inherited Destroy;
end;

Function TtriwacoGrid.XcoordinateSourceNode( const i: Integer ): Double;
begin
  Result := XcoordinatesNodes.Getx( SourceNodes.Getx( i ) );
end;

Function TtriwacoGrid.YcoordinateSourceNode( const i: Integer ): Double;
begin
  Result := YcoordinatesNodes.Getx( SourceNodes.Getx( i ) );
end;

Function TtriwacoGrid.XcoordinateRiverNode( const i: Integer ): Double;
begin
  Result := XcoordinatesNodes.Getx( ListRiverNodes.Getx( i ) );
end;

Function TtriwacoGrid.YcoordinateRiverNode( const i: Integer ): Double;
begin
  Result := YcoordinatesNodes.Getx( ListRiverNodes.Getx( i ) );
end;

Function TtriwacoGrid.XcoordinateBoundaryNode( const i: Integer ): Double;
begin
  Result := XcoordinatesNodes.Getx( ListBoundaryNodes.Getx( i ) );
end;

Function TtriwacoGrid.YcoordinateBoundaryNode( const i: Integer ): Double;
begin
  Result := YcoordinatesNodes.Getx( ListBoundaryNodes.Getx( i ) );
end;

Procedure TtriwacoGrid.ExportRiversToOpenedUngFile( var f: TextFile );
var
  RiverNr, i, j: Integer;
begin
  WriteToLogFile( 'ExportRiversToOpenedUngFile' );
  j := 1;
  for RiverNr:= 1 to NrOfRivers do begin
    Writeln( f, RiverNumber[ RiverNr ] );
    for i:=1 to NrOfNodesPerRiver[ RiverNr ] do begin
      Writeln( f, XcoordinateRiverNode( j ):12:2, ' ', YcoordinateRiverNode( j ):12:2 );
      Inc( j );
    end;
    Writeln( f, 'END' );
  end;
end;

procedure Register;
begin
  RegisterComponents('Triwaco', [TtriwacoGrid]);
end;

initialization
  with FormatSettings do begin {-Delphi XE6}
    DecimalSeparator := '.';
  end;
finalization
end.
