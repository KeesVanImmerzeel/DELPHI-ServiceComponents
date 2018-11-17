// VOOR GEBRUIK VAN DEZE COMPONENTEN: VOER DE ROUTINE
// InitialiseGridIO
// UIT!

unit uTabstractESRIgrid;

interface

uses
  SysUtils, Classes, Vcl.Forms, Vcl.Dialogs,
  uESRI{, ShpAPI129};

type
  PabstractESRIgrid = ^TabstractESRIgrid;
  TabstractESRIgrid = Class( TComponent )
  private { private method cannot be called from another module, and a private field or property cannot be read or written to
            from another module. Het gaat meestal om methods die de fysieke gegevensopslag (variabelen) gebruiken of initiëren }
    FCellSize: Double;
    FfileName: AnsiString;
    FBndBox: TBndBox;
    Procedure WriteMatrixBlockToASC( var f: TextFile; const OffSetRow, OffSetCol, EndRow, EndCol: Integer );
    Function GetBndBox: TBndBox;
    Procedure SetBndBox( const aBndBox: TBndBox );
  Protected  {Members that are intended for use only in the implementation of derived classes are usually protected.}

    {Override deze functies/procedures voor een specifiek grid-type--> override in descendant type}
    Function AllocateMyMemory( const iNRows, iNCols: Integer ): Boolean; Virtual;
    Procedure DeAllocateMyMemory; Virtual;
    Function GetNRows: Integer; Virtual;
    Function GetNCols: Integer; Virtual;
    Function GetColNrFromXcoord( const x: Single ): Integer; virtual;
    Function GetRowNrFromYcoord( const y: Single ): Integer; virtual;
    Procedure WriteMissingValueToLogFile; Virtual;
    Function GetCellType: Integer; Virtual;{ cCELLINT = 1; cCELLFLOAT = 2 }
    Function GetCellMemorySize: Integer; Virtual;
    Function GetMatrixMemorySize: Integer; Virtual;
    Function GetRowMemorySize: Integer; Virtual;
    //Procedure AddValueFieldToPointShape( hDBFHandle: DBFHandle ); Virtual;
    //Procedure WriteValueToPointShape( hDBFHandle: DBFHandle; const Count, RowNr, ColNr: Integer); Virtual;
    //Function SHPCreateObjectFromValue( const RowNr, ColNr: Integer; padfX, padfY, padfM: PDouble ): PShpObject; Virtual;
    Function PtrToAmatrixCell( const RowNr, ColNr: Integer ): Pointer; Virtual;
    Function PtrToMatrix: Pointer; Virtual;
    Function GetWindowRowFromChannel( const Channel, RowNr: Integer ): Boolean; Virtual;
    Function PutWindowRowToChannel( const Channel, RowNr: Integer ): Boolean; Virtual;

    Function ReadRowFromTextFile( var f: TextFile; const RowNr: Integer; const ASCNoDataValue: Double ): Boolean; Virtual;
    Procedure WriteElementToASC( var f: TextFile; const Row, Col: Integer ); Virtual;

    {-Overige Protected functies/procedures (niet specifiek voor grid-type}
    Procedure WriteCharacteristicsToLogFile; Virtual;
    Function IsValidXY( const x, y: Single ): Boolean; Virtual; {-True als (x,y) binnen kaargrenzen ligt}
    Function IsValidRowColNr( const Row, Col: Integer ): Boolean; Virtual; {-True als Row & Col beide een geldige waarde hebben}
    Function GetID: String; Virtual;
    Function GetCellArea: Double; Virtual;
    Function PtrToMatrixRow( const RowNr: Integer ): Pointer; Virtual;
    Function AllocateMemory( const iNRows, iNCols: Integer ): Boolean; Overload; Virtual;
    Destructor Destroy; override;
  public {A public member is visible wherever its class can be referenced.}
    {Override deze functies/procedures voor een specifiek grid-type --> override in descendant type}
    Function IsMissing( const RowNr, ColNr: Integer ): Boolean; Virtual;

    {-Overige Public functies/procedures (niet specifiek voor grid-type)}
    {-With SaveAs does not work after creation? }
// TODO: Test SaveAs na initialisatie met Create
    Constructor Create( const iNRows, iNCols: Integer; var iResult: Integer; AOwner: TComponent ); Reintroduce; Virtual;
    Constructor InitialiseFromESRIGridFile( const iFileName: TFileName;
      var iResult: Integer; AOwner: TComponent; dummy : integer = 0 ); Virtual;
    {-Initialise ESRI (Arc/Info) grid from ASC-file }
    Constructor CreateFromASCfile( const ASCfileName: TFileName;
      var iResult: Integer; AOwner: TComponent; dummy : integer = 0 ); Virtual;
    Constructor Clone( const aAbstractESRIgrid: TabstractESRIgrid;
      const NewName: String; var iResult: Integer; AOwner: TComponent); Overload; Virtual;
    Constructor Clone( const aAbstractESRIgrid: TabstractESRIgrid;
      const NewName: String; const RefineFactor: Integer;
      var iResult: Integer; AOwner: TComponent); Overload; Virtual;
    Function SaveAs( const iFileName: TFileName ): Integer; overload; Virtual;
    Function SaveAs( const iFileName: TFileName; const newBndBox: TBndBox ): Integer; overload; Virtual;
    //Function ExportToPointShape( const iFileName: TFileName ): Integer; Virtual;
    Function OnlyHasMissingValues: Boolean; Virtual;
    Function FractionOfAreaWithData: Double; Virtual;
    Procedure GetCellCentre( const Row, Col: Integer; var x, y: Single ); Virtual;
    Function ValidRowColNr( const Row, Col: Integer ): Boolean; Virtual;
    Procedure XYToWindowColRow( const x, y: Single; var Row, Col: Integer ); Virtual;
    Function ExportToASC( const iFileName: TFileName; const fNameXYformat: Boolean=FALSE ): Integer; Overload; Virtual;
    Function ExportToASC( const iFileName: TFileName; const newBndBox: TBndBox ): Integer; Overload; Virtual;
    // Export in PEST format. Missing data is skipped!
    Function ExportToPEST( const iFileName: TFileName; skipMissingValues: Boolean=TRUE ): Integer; Virtual;
    {-Public properties}
    Property FileName: AnsiString Read FfileName Write FfileName;
    Property ID: String Read GetID;
    Property NRows: Integer Read GetNRows;
    Property NCols: Integer Read GetNCols;
    Property xMin: Double Read Fbndbox[0] Write Fbndbox[0];
    Property xMax: Double Read Fbndbox[2] Write Fbndbox[2];
    Property yMin: Double Read Fbndbox[1] Write Fbndbox[1];
    Property yMax: Double Read Fbndbox[3] Write Fbndbox[3];
    Property CellSize: Double read FCellSize write FCellSize;
    Property CellArea: Double Read GetCellArea;
    Property BndBox: TBndBox Read GetBndBox Write SetBndBox;
    Published {Used to display properties in the Object Inspector}
  end;

  E_Error_Allocating_Memory_For_TabstractESRIgrid_Or_descendant = class( Exception );
  E_Error_Initialising_TabstractESRIgrid_Descendant_From_File = class( Exception );
  E_invalid_ESRI_GRID_raster_dataset = class( Exception );
  E_ESRI_GRID_raster_dataset_could_not_be_opened = class( Exception );
  EInvalid_ESRI_GRID_raster_CellType = class( Exception );
  E_ErrorBndCellRead = class( Exception );
  E_ErrorAccessWindowSetResult = class( Exception );
  E_Error_ESRI_grid_already_exists = class (Exception );
  E_ESRI_GRID_raster_dataset_could_not_be_created = class (Exception );
  E_ESRI_GRID_raster_dataset_could_not_be_created_BND_boxError  = class (Exception );
  E_ASC_File_does_not_exist  = class ( Exception );
  E_Couldnot_read_ASC_heading = class( Exception );

Resourcestring
  sE_Error_Allocating_Memory_For_TabstractESRIgrid_Or_descendant = 'Error allocating memory for TabstractESRIgrid (or descendant).';
  sE_Error_Initialising_TabstractESRIgrid_Descendant_From_File = 'Error initialising TabstractESRIgrid (descendant) from file [%s].';
  sE_invalid_ESRI_GRID_raster_dataset = '[%s] is not a (valid) ESRI GRID raster dataset.';
  sE_ESRI_GRID_raster_dataset_could_not_be_opened = 'ESRI GRID raster dataset [%s] could not be opened.';
  sEInvalid_ESRI_GRID_raster_CellType = 'Invalid ESRI GRID raster CellType';
  sErrorBndCellRead = 'BndCellRead of ESRI GRID raster dataset [%s] not OK. BndCellReadResult = [%d]';
  sErrorAccessWindowSetResult = 'AccessWindowSetResult of ESRI GRID raster dataset [%s] not OK:  [%d]';
  sE_Error_Initialising_ESRIgrid_matrix = 'Error initialising matrix for TabstractESRIgrid.';
  sE_Error_ESRI_grid_already_exists = 'Error: ESRI grid already exists: [%s]';
  sE_ESRI_GRID_raster_dataset_could_not_be_created = 'ESRI GRID raster dataset [%s] could not be created.';
  sE_ESRI_GRID_raster_dataset_could_not_be_created_BND_boxError =
    'ESRI GRID raster dataset [%s] could not be created due to BND-box error.';
  sE_ASC_File_does_not_exist = 'ASC file [%s] does not exist.';
  sE_Couldnot_read_ASC_heading = 'Could not read heading of ASC file [%s]';

const
  ASCnoValue = -9999;

  {-True if newBndBox at least partly overlaps OldBndBox}
Function ClipNewBndBox( var newBndBox: TBndBox; const OldBndBox: TBndBox ): Boolean;
Function IsArcViewBinaryGrid( const aDirectory: TFileName ): Boolean;

implementation

uses
  Controls, Math,
  uError, OPWstring, AVGRIDIO;

Function ClipNewBndBox( var newBndBox: TBndBox; const OldBndBox: TBndBox ): Boolean;
begin
  newBndBox[ cxMin ] := Max( newBndBox[ cxMin ], OldBndBox[ cxMin ] );
  newBndBox[ cyMin ] := Max( newBndBox[ cyMin ], OldBndBox[ cyMin ] );
  newBndBox[ cxMax ] := Min( newBndBox[ cxMax ], OldBndBox[ cxMax ] );
  newBndBox[ cyMax ] := Min( newBndBox[ cyMax ], OldBndBox[ cyMax ] );
  Result := ( newBndBox[ cxMax ] > newBndBox[ cxMin ] ) and ( newBndBox[ cyMax ] > newBndBox[ cyMin ] )
end;

Function IsArcViewBinaryGrid( const aDirectory: TFileName ): Boolean;
begin
  Result := DirectoryExists( aDirectory ) and
            FileExists( aDirectory + '\' + 'hdr.adf' ) and
            FileExists( aDirectory + '\' + 'sta.adf' ) and
            DirectoryExists( ExtractFileDir(  aDirectory ) + '\info' );
end;

{-TabstractESRIgrid-------------------------------------------------------------------------------}

Function TabstractESRIgrid.GetBndBox: TBndBox;
begin
  Move( FBndBox, Result, SizeOf( TBndBox  ) );
end;

Constructor TabstractESRIgrid.Clone( const aAbstractESRIgrid: TabstractESRIgrid;
  const NewName: String; var iResult: Integer; AOwner: TComponent);
var
  Row: Integer;
begin
  Create( aAbstractESRIgrid.NRows, aAbstractESRIgrid.NCols, iResult, AOwner );
  if iResult <> cNoError then begin
    MessageDlg( 'Error in "TAbstractESRIgrid.Clone".', mtError, [mbOk], 0);
    Exit;
  end;
  Move( aAbstractESRIgrid.PtrToMatrix^, PtrToMatrix^, GetMatrixMemorySize );
  FileName := NewName;
  xMin   := aAbstractESRIgrid.xMin;
  xMax   := aAbstractESRIgrid.xMax;
  yMin   := aAbstractESRIgrid.yMin;
  yMax   := aAbstractESRIgrid.yMax;
  CellSize := aAbstractESRIgrid.CellSize;
  WriteToLogFileFmt( 'Grid [%s] created by cloning. Size=[%d]', [FileName, GetMatrixMemorySize] );
end;

Constructor TabstractESRIgrid.Clone( const aAbstractESRIgrid: TabstractESRIgrid;
      const NewName: String; const RefineFactor: Integer;
      var iResult: Integer; AOwner: TComponent);
var
  Row, Col, targetRow, targetCol, CellMemorySize, RowMemorySize,
  i, j: Integer;
begin
  Create( RefineFactor*aAbstractESRIgrid.NRows, RefineFactor*aAbstractESRIgrid.NCols,
    iResult, AOwner );

  if iResult <> cNoError then begin
    MessageDlg( 'Error in "TAbstractESRIgrid.Clone".', mtError, [mbOk], 0);
    Exit;
  end;

  CellMemorySize := GetCellMemorySize;
  RowMemorySize := GetRowMemorySize;
  for Row := 1 to aAbstractESRIgrid.NRows do begin
    targetRow := RefineFactor*(Row-1)+1;
    for Col := 1 to aAbstractESRIgrid.NCols do begin
      targetCol := RefineFactor*(Col-1)+1;
      for j := targetCol to targetCol+RefineFactor-1 do
        Move( aAbstractESRIgrid.PtrToAmatrixCell(Row,Col)^,
          PtrToAmatrixCell( targetRow, j )^, CellMemorySize );
    end;
    for i:=targetRow+1 to targetRow+RefineFactor-1 do
      move( PtrToMatrixRow( targetRow )^, PtrToMatrixRow( i )^, RowMemorySize );
  end;

  FileName := NewName;
  xMin   := aAbstractESRIgrid.xMin;
  xMax   := aAbstractESRIgrid.xMax;
  yMin   := aAbstractESRIgrid.yMin;
  yMax   := aAbstractESRIgrid.yMax;
  CellSize := aAbstractESRIgrid.CellSize / RefineFactor;    // Hierop loopt hij vast bij saveas...
  WriteToLogFileFmt( 'Grid [%s] created by cloning. Refine factor = [%d]',
  [NewName, RefineFactor] );
end;

Procedure TabstractESRIgrid.SetBndBox( const aBndBox: TBndBox );
begin
  Move( aBndBox, FBndBox, SizeOf( TBndBox  ) );
end;

{Function TabstractESRIgrid.ExportToPointShape( const iFileName: TFileName ): Integer;
var
  Count: LongInt;
  i, j, iNCols, iNRows: Integer;
  Save_Cursor: TCursor;
  x, y: Single;
  hSHPHandle:  SHPHandle;
  hDBFHandle:  DBFHandle;
  psShape   :  PSHPObject;
  xd, yd, md:  Double;
  nSHPType: LongInt;
  ansiFileName, FieldName: AnsiString;
begin
  WriteToLogFile( 'Export TAbstractESRIgrid (or descendant) to point shape.' );
  Save_Cursor := Screen.Cursor;
  Result := cUnknownError;
  Try
    Screen.Cursor := crHourglass;
    Try
      // Create the Shapefile
      ansiFileName := iFilename;
      nSHPType := SHPT_POINT;
      //hSHPHandle := SHPCreate( PAnsiChar(ansiFileName) , nSHPType );
      //hDBFHandle := DBFCreate( PAnsiChar(ansiFileName));
      hSHPHandle := SHPCreate( PANSIChar(ansiFileName) , nSHPType );
      hDBFHandle := DBFCreate( PANSIChar(ansiFileName));

      DBFAddField(hDBFHandle,'ID',FTInteger,11,0);
      AddValueFieldToPointShape( hDBFHandle );
      iNCols := NCols;
      iNRows := NRows;
      Count := 0;
      mD := 0;
      for i:=1 to iNRows do begin
        for j:= 1 to iNCols do begin
          if not IsMissing( i, j ) then begin
            GetCellCentre( i, j, x, y );
            xd := x; yd := y;
            // Store it into a shape object
            psShape := SHPCreateObjectFromValue( i, j, @xd, @yd, @mD );
            // write this object to the file
            SHPWriteObject( hSHPHandle, -1, psShape );
            DBFWriteIntegerAttribute( hDBFHandle, Count, 0, Count ); //hDBFHandle, iShape, iField, Fieldvalue
            WriteValueToPointShape( hDBFHandle, Count, i, j );
            // and dismiss this object
            SHPDestroyObject( psShape );
            Inc( Count );
          end; //-if
        end;
      end;
      SHPClose( hSHPHandle );
      DBFClose( hDBFHandle );
      WriteToLogFile( 'TAbstractESRIgrid (or descendant) exported to point shape.' );
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    Screen.Cursor := Save_Cursor;
  end;
end; {-Function TAbstractESRIgrid.ExportToPointShape}

{Function TabstractESRIgrid.SHPCreateObjectFromValue( const RowNr, ColNr: Integer; padfX, padfY, padfM: PDouble ): PShpObject;
begin
end;

Procedure TabstractESRIgrid.WriteValueToPointShape( hDBFHandle: DBFHandle; const Count, RowNr, ColNr: Integer);
begin
end;}

Procedure TabstractESRIgrid.WriteMatrixBlockToASC( var f: TextFile; const OffSetRow, OffSetCol, EndRow, EndCol: Integer );
var
  i, j: Integer;
begin
  for i:=OffSetRow to EndRow do begin
    for j:= OffSetCol to EndCol do
      WriteElementToASC( f, i, j );
    Writeln( f );
  end;
end;

Procedure TabstractESRIgrid.WriteElementToASC( var f: TextFile; const Row, Col: Integer );
begin
end;

Procedure TabstractESRIgrid.WriteMissingValueToLogFile;
begin
end;

Function TabstractESRIgrid.ValidRowColNr( const Row, Col: Integer ): Boolean;
begin
  Result := ( ( Row > 0 ) and ( Row <= NRows ) and ( Col > 0 ) and ( Col <= NCols ) );
end;

Procedure TabstractESRIgrid.XYToWindowColRow( const x, y: Single; var Row, Col: Integer );
begin
  Row := GetRowNrFromYcoord( y ); Col := GetColNrFromXcoord( x );
end;

Function TabstractESRIgrid.AllocateMyMemory( const iNRows, iNCols: Integer ): Boolean;
begin
  Result := true;
  Try
  except
    Result := false;
  End;
end;

Function TabstractESRIgrid.AllocateMemory( const iNRows, iNCols: Integer ): Boolean;
var
  Save_Cursor: TCursor;
begin
  WriteToLogFile( 'Allocate memory for TabstractESRIgrid (or descendant).' );
  Result := False;
  Save_Cursor := Screen.Cursor;
  Screen.Cursor := crHourglass;
  if AllocateMyMemory( iNRows, iNCols ) then
    Result := True
  else
    HandleError( sE_Error_Initialising_TabstractESRIgrid_Descendant_From_File, false );
  Screen.Cursor := Save_Cursor;
end;

Function TabstractESRIgrid.GetCellArea: Double;
begin
  Result := Sqr( CellSize );
end;

Function TabstractESRIgrid.GetCellType: Integer; {cCELLINT = 1; cCELLFLOAT = 2 }
begin
  Result := cCELLFLOAT;
end;

Function TabstractESRIgrid.GetCellMemorySize: Integer;
begin
  Result := 0;
end;

Function TabstractESRIgrid.GetMatrixMemorySize: Integer;
begin
  Result := 0;
end;

Function TabstractESRIgrid.GetRowMemorySize: Integer;
begin
  Result := GetCellMemorySize * NCols;
end;

{Procedure TabstractESRIgrid.AddValueFieldToPointShape( hDBFHandle: DBFHandle );
begin
end;}

Procedure TabstractESRIgrid.DeAllocateMyMemory;
begin
end;

Function TabstractESRIgrid.OnlyHasMissingValues: Boolean;
var
  i, j, iNRows, iNCols: Integer;
begin
  Result := false;
  iNRows := NRows;
  iNCols := NCols;
  for i:=1 to iNRows do
    for j:=1 to iNCols do
      if IsMissing( i, j ) then
        Exit;
  Result := true;
end;

Function TabstractESRIgrid.FractionOfAreaWithData: Double;
var
  i, j, k, iNRows, iNCols: Integer;
begin
  iNRows := NRows;
  iNCols := NCols;
  k := 0;
  for i:=1 to iNRows do
    for j:=1 to iNCols do
      if IsMissing( i, j ) then
        Inc( k );
  Result := k / ( iNRows * iNCols );
end;

Procedure TabstractESRIgrid.GetCellCentre( const Row, Col: Integer; var x, y: Single );
begin
  x := xMin + ( Col - 0.5 ) * CellSize;
  y := yMax - ( Row - 0.5) * CellSize;
end;

Function TabstractESRIgrid.GetID: String;
var
  i: Integer;
begin
  Result := FileName;
  repeat
    i := Pos( '\', Result );
    if i <> 0 then begin
      Result := copy( Result, i+1, Length( FileName ) );
    end;
  until ( i = 0 );
  Result := ChangeFileExt( Result, '' );
end;

Function TabstractESRIgrid.PtrToAmatrixCell( const RowNr, ColNr: Integer ): Pointer; {Specifiek voor grid-type}
begin
  Result := NIL;
end;

Function TabstractESRIgrid.PtrToMatrix: Pointer;
begin
  Result := NIL;
end;

Function TabstractESRIgrid.PtrToMatrixRow( const RowNr: Integer ): Pointer;
begin
  Result := PtrToAmatrixCell( RowNr, 1 );
end;

Function TabstractESRIgrid.SaveAs( const iFileName: TFileName ): Integer;
var
  Channel, i, AccessWindowSetResult, MyCellType: Integer;
  Save_Cursor: TCursor;
  SaveFileName: AnsiString;
  Ptr: ^TCELLTYPE;
  myBndBox: TBndBox;
  MyCellSize: Double;
begin
  WriteToLogFile( 'TabstractESRIgrid (or descendant) SaveAs' );
  Result := cUnknownError;
  Save_Cursor := Screen.Cursor;
  Screen.Cursor := crHourglass;
  Try
    Try
      {-Open ESRI GRID raster dataset}
      SaveFileName := Trim( iFileName );
      WriteToLogFileFmt( 'TabstractESRIgrid (or descendant) SaveAs [%s].', [SaveFileName] );
      if ( GridIOSetup < 0 ) then
        Raise Exception.CreateRes( @sErrorInitiating_IO_Library_for_ESRI_GRID_raster_datasets );
      WriteToLogFile( 'IO library for ESRI GRID raster datasets is initiated (GridIOSetup).' );
      if ( ( CellLyrExists( PANSIChar( SaveFileName ) ) = cTRUE ) ) then  begin
        GridKill( PAnsiChar( SaveFileName ), 0 );
      end;
      WriteToLogFile( 'Open channel...' );
      myBndBox := BndBox;
      MyCellType := GetCellType;
      MyCellSize :=  CellSize;
      // Showmessage( ' pause' );
      WriteToLogFileFmt( 'SaveFileName: [%s].', [SaveFileName] );
      WriteToLogFileFmt( 'MyCellType: [%d].', [MyCellType] );
      WriteToLogFileFmt( 'CellSize: [%f].', [CellSize] );
      WriteToLogFileFmt( 'xMin, yMin, xMax, yMax: [%f] [%f] [%f] [%f].',
        [MyBndBox[cxMin], MyBndBox[cyMin], MyBndBox[cxMax], MyBndBox[cyMax ] ] );

      channel := CellLayerCreate( PAnsiChar( SaveFileName ), cWRITEONLY,
          {cCELLIO}cROWIO, MyCellType, MyCellSize, MyBndBox );



      if ( channel < 0 ) then
        Raise Exception.CreateResFmt( @sE_ESRI_GRID_raster_dataset_could_not_be_created,
            [ExpandFileName( SaveFileName )] );
      WriteToLogFile( 'Channel opened. AccessWindowSetResult...' );
      AccessWindowSetResult := AccessWindowSet( MyBndBox, CellSize, MyBndBox );
      if ( AccessWindowSetResult < 0 ) then
        Raise Exception.CreateResFmt( @sErrorAccessWindowSetResult,
        [ExpandFileName( SaveFileName ), AccessWindowSetResult ] );
      WriteToLogFileFmt( 'AccessWindowSetResult OK:  [%d]', [AccessWindowSetResult] );
      {-Allocate data}
      WriteToLogFile( 'Allocating data...' );

      for i:=1 to NRows do begin
        Ptr := PtrToMatrixRow( i );
        PutWindowRow( channel, i-1, Ptr^ );
      end;

      CellLyrClose(channel);
      WriteToLogFile( 'Done.' );
      Result := cNoError;
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    Screen.Cursor := Save_Cursor;
    Try
      GridIOExit;
    Except
    end;
  end;
end; {-Function TabstractESRIgrid.SaveAs}

Function TabstractESRIgrid.SaveAs( const iFileName: TFileName; const newBndBox: TBndBox ): Integer;
var
  Channel, i, AccessWindowSetResult, OffSetRow, OffSetCol, NewNRows, MyCellType: Integer;
  Save_Cursor: TCursor;
  SaveFileName: AnsiString;
  Ptr: ^TCELLTYPE;
  NwBndBox: TBndBox;
  MyCellSize: Double;
begin
  WriteToLogFile( 'TabstractESRIgrid.SaveAs' );
  Result := cUnknownError;
  Save_Cursor := Screen.Cursor;
  Screen.Cursor := crHourglass;
  Try
    Try
      Move( NewBndBox, NwBndBox, SizeOf( TBndBox ) );
      if not ClipNewBndBox( NwBndBox, BndBox ) then
        Raise Exception.CreateResFmt( @sE_ESRI_GRID_raster_dataset_could_not_be_created_BND_boxError,
            [SaveFileName] );

      {-Open ESRI GRID raster dataset}
      SaveFileName := AnsiString ( Trim( iFileName ) );
      if ( GridIOSetup < 0 ) then
        Raise Exception.CreateRes( @sErrorInitiating_IO_Library_for_ESRI_GRID_raster_datasets );
      WriteToLogFile( 'IO library for ESRI GRID raster datasets is initiated (GridIOSetup).' );
      if ( ( CellLyrExists( PAnsiChar( SaveFileName ) ) = cTRUE ) ) then  begin
        GridKill( PAnsiChar( SaveFileName ), 0 );
      end;
      MyCellType :=  GetCellType;
      MyCellSize :=  CellSize;
      channel := CellLayerCreate( PAnsiChar( SaveFileName ), cWRITEONLY, cROWIO, MyCellType, MyCellSize, NwBndBox );
      if ( channel < 0 ) then
        Raise Exception.CreateResFmt( @sE_ESRI_GRID_raster_dataset_could_not_be_created,
            [SaveFileName] );
      AccessWindowSetResult := AccessWindowSet( NwBndBox, CellSize, NwBndBox );
      if ( AccessWindowSetResult < 0 ) then
        Raise Exception.CreateResFmt( @sErrorAccessWindowSetResult,
        [ExpandFileName( SaveFileName ), AccessWindowSetResult ] );
      WriteToLogFileFmt( 'AccessWindowSetResult OK:  [%d]', [AccessWindowSetResult] );

      OffSetRow := GetRowNrFromYcoord( NwBndBox[cyMax] - 0.5*CellSize ); WriteToLogFileFmt( 'OffSetRow= %d.', [OffSetRow] );
      OffSetCol := GetColNrFromXcoord( NwBndBox[cxMin] + 0.5*CellSize ); WriteToLogFileFmt( 'OffSetCol= %d', [OffSetCol] );
      NewNRows := WindowRows; WriteToLogFileFmt( 'New Nr. of rows: %d',[NewNRows] );
      {-Allocate data}
      WriteToLogFile( 'Allocating data...' );
      for i:=1 to NewNRows do begin
        Ptr := PtrToAmatrixCell( OffSetRow + i - 1, OffSetCol );
        Try
          PutWindowRow( channel, i-1, Ptr^ );
        Except
          Result := -i;
          raise Exception.CreateFmt('Error in SaveAs: PutWindowRow %d', [Result] );
        End;
      end;

      CellLyrClose(channel);
      WriteToLogFileFmt( 'Done. Saved as [%s]', [SaveFileName] );
      Result := cNoError;
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    Screen.Cursor := Save_Cursor;
    Try
      GridIOExit;
    Except
    end;
  end;
end; {-Function TabstractESRIgrid.SaveAs}

Function TabstractESRIgrid.IsMissing( const RowNr, ColNr: Integer ): Boolean;
begin
  Result := true;
end;

Procedure WriteASCheading( var f: TextFile; const Ncols, Nrows: Integer; const xllcorner, yllcorner, CellSize: Single );
begin
  Writeln( f, 'ncols         ', NCols );
  Writeln( f, 'nrows         ', NRows );
  Writeln( f, 'xllcorner     ' + GetAdoGetal( xllcorner ) );
  Writeln( f, 'yllcorner     ' + GetAdoGetal( yllcorner ) );
  Writeln( f, 'cellsize      ' + GetAdoGetal( CellSize ) );
  Writeln( f, 'NODATA_value  ' + '-9999' );
end;

Function ReadASCheading( var f: TextFile; var Ncols, Nrows: Integer; var xllcorner, yllcorner, CellSize,
  ASCNoDataValue: Double ): Boolean;
Const
  WordDelims: CharSet = [' '];
var
  S: String;
  Code, Len: Integer;
  SResult: String;
  Procedure LeesRegel;
  begin
    Readln( f, S ); SResult := ExtractWord( 2, S, WordDelims, Len );
  end;
begin
  Result := True;
  Try
    LeesRegel; Val( SResult, NCols, Code ); if Code <> 0 then raise Exception.Create('');
    LeesRegel; Val( SResult, NRows, Code ); if Code <> 0 then raise Exception.Create('');
    LeesRegel; Val( SResult, xllcorner, Code ); if Code <> 0 then raise Exception.Create('');
    LeesRegel; Val( SResult, yllcorner, Code ); if Code <> 0 then raise Exception.Create('');
    LeesRegel; Val( SResult, CellSize, Code ); if Code <> 0 then raise Exception.Create('');
    LeesRegel; Val( SResult, ASCNoDataValue, Code ); if Code <> 0 then raise Exception.Create('');
  Except
    Result := False;
  End;
end;


Function TabstractESRIgrid.ExportToASC( const iFileName: TFileName; const fNameXYformat: Boolean=FALSE ): Integer;
var
  i, j, iNCols, iNRows: Integer;
  f: TextFile;
  x, y: Single;
  fName: String;
  Missing: Boolean;
begin
  Result := cUnknownError;
  Try Try
    AssignFile( f, iFileName ); Rewrite( f );

    if not fNameXYformat then
      WriteASCheading( f, Ncols, Nrows, xMin, yMin, CellSize )
    else begin
      //Writeln( f, 'fName,x,y,value' );
      fName := JustName( iFileName );
    end;
    iNCols := NCols;
    iNRows := NRows;

    for i:=1 to iNRows do begin
      for j:= 1 to iNCols do begin
        Missing := IsMissing( i, j );

          if (not fNameXYformat) then begin
            WriteElementToASC( f, i, j );
            Writeln( f );
          end else begin
            if ( not Missing ) then begin
              GetCellCentre( i, j,  x, y );
              Write( f, Format('%s, %.2f %.2f ', [fName, x, Y]) + ', ' );
              WriteElementToASC( f, i, j );  Writeln(f);
            end;
        end;
      end;
    end;
    Result := cNoError
    Except
    end
  Finally
    Try CloseFile( f ); except end;
  end;
end;

Function TabstractESRIgrid.ExportToASC( const iFileName: TFileName; const newBndBox: TBndBox ): Integer;
var
  OffSetRow, OffSetCol, EndRow, EndCol: Integer;
  f: TextFile;
  x, y: Single;
begin
  WriteToLogFileFmt( 'ExportToASC [%s].', [ExpandFileName( iFileName )] );
  Result := cUnknownError;
  Try Try
    OffSetRow := GetRowNrFromYcoord( NewBndBox[cymax] - 0.5*CellSize ); WriteToLogFileFmt( 'OffSetRow= %d.', [OffSetRow] );
    EndRow := GetRowNrFromYcoord( NewBndBox[cymin] + 0.5*CellSize );    WriteToLogFileFmt( 'EndRow= %d.', [EndRow] );
    OffSetCol := GetColNrFromXcoord( NewBndBox[cxmin] + 0.5*CellSize ); WriteToLogFileFmt( 'OffSetCol= %d.', [OffSetCol] );
    EndCol := GetColNrFromXcoord( NewBndBox[cxmax] - 0.5*CellSize ); WriteToLogFileFmt( 'EndCol= %d.', [EndCol] );
    GetCellCentre( EndRow, OffSetCol, x, y );
    AssignFile( f, iFileName ); Rewrite( f );
    WriteASCheading( f, EndCol - OffSetCol + 1, EndRow - OffSetRow + 1, x - CellSize / 2, y - CellSize / 2, CellSize );
    WriteMatrixBlockToASC( f, OffSetRow, OffSetCol, EndRow, EndCol );
    Result := cNoError
    Except
    end
  Finally
    Try CloseFile( f ); except end;
  end;
end;

Function TabstractESRIgrid.ExportToPEST( const iFileName: TFileName;
  skipMissingValues: Boolean=TRUE ): Integer;
var
  nr, i, j: Integer;
  f: TextFile;
  x, y: Single;
  Missing: Boolean;
begin
  WriteToLogFileFmt( 'ExportToPEST [%s].', [ExpandFileName( iFileName )] );
  Result := cUnknownError;
  Try Try
    AssignFile( f, iFileName ); Rewrite( f );
    Writeln( f, Format( '%9s %19s %19s %19s', ['nr', 'x', 'y', id ] ) );
    nr := 1;
    for i:=1 to NRows do begin
      for j:= 1 to NCols do begin
        Missing := IsMissing( i, j );
        if ( not Missing ) or ( Missing and (not SkipMissingValues )) then begin
          GetCellCentre( i, j, x, y );
          Write( f, format( '%9d %19f %19f', [nr, x, y]  ) );
          Write( f, '   ' );
          WriteElementToASC( f, i, j ); Writeln( f );
        end;
        nr := nr + 1;
      end;
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

Constructor TabstractESRIgrid.Create( const iNRows, iNCols: Integer; var iResult: Integer; AOwner: TComponent );
var
  Save_Cursor: TCursor;
begin
  WriteToLogFile( 'TabstractESRIgrid or descendant Create.' );
  iResult := cUnknownError;
  Inherited Create( AOwner );
  Save_Cursor := Screen.Cursor;
  Try
    Screen.Cursor := crHourglass;
    Try
      WriteToLogFile( 'Try to allocate memory' );
      if AllocateMyMemory( iNRows, iNCols ) then
        iResult := cNoError;
      if ( iResult <> cNoError ) then
        Raise Exception.CreateRes(
          @sE_Error_Allocating_Memory_For_TabstractESRIgrid_Or_descendant );
      xMin := 0;
      xMax := iNCols;
      yMin := 0;
      yMax := iNRows;
      CellSize := 1;
      FileName := 'ESRIgrd';
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
        DeAllocateMyMemory;
      end;
    end;
  Finally;
    Screen.Cursor := Save_Cursor;
  end;
end;

Procedure TabstractESRIgrid.WriteCharacteristicsToLogFile;
begin
  WriteToLogFileFmt( '  FileName = [%s]', [FileName] );
  WriteToLogFileFmt( '  NCols = %d', [NCols] );
  WriteToLogFileFmt( '  NRows = %d', [NRows] );
  WriteToLogFileFmt( '  xMin = %g', [xMin] );
  WriteToLogFileFmt( '  xMax = %g', [xMax] );
  WriteToLogFileFmt( '  yMin = %g', [yMin] );
  WriteToLogFileFmt( '  yMax = %g', [yMax] );
  WriteMissingValueToLogFile;
  WriteToLogFileFmt( '  CellSize =  %g', [CellSize] );
end;

Function TabstractESRIgrid.IsValidXY( const x, y: Single ): Boolean;
begin
  Result := ( x >= xMin ) and ( x < xMax ) and ( y >= yMin ) and ( y < yMax );
end;

Function TabstractESRIgrid.IsValidRowColNr( const Row, Col: Integer ): Boolean;
begin
  Result := ( Row > 0 ) and ( Row <= GetNRows ) and ( Col > 0 ) and ( Row <= GetNCols );
end;

Function TabstractESRIgrid.GetColNrFromXcoord( const x: Single ): Integer;
begin
  Result := EnsureRange( Round( (x-xMin-CellSize/2)/CellSize + 1), 1, GetNCols );
end;

Function TabstractESRIgrid.GetRowNrFromYcoord( const y: Single ): Integer;
begin
  Result := EnsureRange( Round( (yMax-y-CellSize/2)/CellSize + 1), 1, GetNRows );
end;

Destructor  TabstractESRIgrid.Destroy;
begin
  DeAllocateMyMemory;
  Inherited Destroy;
end;

Function TabstractESRIgrid.GetNRows: Integer;
begin
end;

Function TabstractESRIgrid.GetNCols: Integer;
begin
end;

Constructor TabstractESRIgrid.InitialiseFromESRIGridFile( const iFileName: TFileName;
      var iResult: Integer; AOwner: TComponent; dummy : integer = 0 );
var
  Channel, i, BndCellReadResult, AccessWindowSetResult, iNRows, iNCols, CellType: Integer;
  iCellSize: Double;
  tmpBndBox, newbox: TBndBox;
  Save_Cursor: TCursor;
begin
  WriteToLogFile( 'Initialise TabstractESRIgrid (or descendant) from ESRIGrid-file.' );
  iResult := cUnknownError;
  Save_Cursor := Screen.Cursor;
  Try
    Screen.Cursor := crHourglass;
    Try
      {-Open ESRI GRID raster dataset}
      FileName := Trim( iFileName );
      WriteToLogFileFmt( 'Check existance of directory [%s].' + #13 +
        'Reject this directory as an ESRI-grid folder if the directory-name contains spaces.', [ FileName ] );
      if not DirectoryExists( FileName ) or
        ( Pos( ' ', FileName ) <> 0 ) then
        Raise Exception.CreateResFmt( @sE_invalid_ESRI_GRID_raster_dataset, [ FileName  ] );
      WriteToLogFileFmt( 'Directory [%s] exists (and dir-name does not contain spaces).', [ FileName ] );

      if ( GridIOSetup < 0 ) then
        Raise Exception.CreateRes( @sErrorInitiating_IO_Library_for_ESRI_GRID_raster_datasets );

      WriteToLogFile( 'IO library for ESRI GRID raster datasets is initiated (GridIOSetup).' );
      if ( not ( CellLyrExists( PAnsiChar( FileName ) ) = cTRUE ) ) then
        Raise Exception.CreateResFmt( @sE_invalid_ESRI_GRID_raster_dataset,
          [ExpandFileName( FileName ) ] );

      CellType := GetCellType;
      channel := CellLayerOpen( PANSIChar( FileName ), cREADONLY, cCELLIO, CellType, iCellSize );
      if ( channel < 0 ) then
        Raise Exception.CreateResFmt( @sE_ESRI_GRID_raster_dataset_could_not_be_opened,
            [FileName] );

      WriteToLogFileFmt( 'ESRI grid [' + FileName + '] is geopend. ' + #13 +
        'channel= [%d]' + #13 +
        'celltype= [%d]' + #13 +
        'cellsize= [%g]', [channel, Celltype, CellSize] );

      GetMissingFloat( @MissingSingle );

      if ( CellType <> GetCellType ) then
        Raise Exception.CreateRes( @sEInvalid_ESRI_GRID_raster_CellType );

      BndCellReadResult := BndCellRead( PAnsiChar( FileName ), tmpBndBox );
      if ( BndCellReadResult < 0 ) then
        Raise Exception.CreateResFmt( @sErrorBndCellRead,
            [ExpandFileName( FileName ), BndCellReadResult ] );

      WriteToLogFileFmt( 'BndCellRead [%s] OK. ' + #13 +
        'value0 = [%g]' + #13 + 'value1 = [%g]'  + #13 +
        'value2 = [%g]' + #13 + 'value3 = [%g]',
        [ExpandFileName( FileName ), TmpBndBox[0], TmpBndBox[1], TmpBndBox[2], TmpBndBox[3]] );

      AccessWindowSetResult := AccessWindowSet( TmpBndBox, iCellSize, newbox );
      if ( AccessWindowSetResult < 0 ) then
        Raise Exception.CreateResFmt( @sErrorAccessWindowSetResult,
        [ExpandFileName( FileName ), AccessWindowSetResult ] );
      WriteToLogFileFmt( 'AccessWindowSetResult OK:  [%d]', [AccessWindowSetResult] );

      iNRows := WindowRows; WriteToLogFileFmt( 'Nr. of rows: %d',[iNRows] );
      iNCols := WindowCols; WriteToLogFileFmt( 'Nr. of cols: %d',[iNCols] );

      {-Allocate data}

      WriteToLogFile( 'Allocate data...' );
      Create( iNRows, iNCols, iResult, AOwner );
      if iResult <> cNoError then
        Raise Exception.CreateResFmt( @sE_Error_Initialising_ESRIgrid_matrix, [iFileName] );

      WriteToLogFile( 'Matrix is initiated.' );

      {-Wijs interne variabelen pas definitief toe NADAT 'inherited create' is aangeroepen
        (anders worden de eerder toegewezen waarden overschreven) }
      FileName := Trim( JustName( iFileName ) );
      CellSize := iCellSize;
      Move( tmpBndBox, FBndBox, SizeOf( TBndBox ) );

      WriteToLogFile( 'Allocating data...' );
      for i:=1 to NRows do begin
        if not GetWindowRowFromChannel( Channel, i ) then begin
          iResult := -i;
          Raise E_Error_Allocating_Memory_For_TabstractESRIgrid_Or_descendant.CreateRes(
            @sE_Error_Allocating_Memory_For_TabstractESRIgrid_Or_descendant );
        end;
      end;
      WriteToLogFile( 'Done.' );

      WriteCharacteristicsToLogFile;
      iResult := cNoError;
    Finally
      Screen.Cursor := Save_Cursor;
      Try
        GridIOExit;
      Except
      end;
    end;
  Except
    On E: E_Error_Allocating_Memory_For_TabstractESRIgrid_Or_descendant do begin
      HandleError( E.Message, false );
    end;
    On E: Exception do begin
      HandleError( E.Message, true );
    end;
  end;
end; {-Constructor TabstractESRIgrid.InitialiseFromESRIGridFile}

Constructor TabstractESRIgrid.CreateFromASCfile( const ASCfileName: TFileName;
  var iResult: Integer; AOwner: TComponent; dummy : integer = 0 );
var
  i, iNRows, iNCols: Integer;
  iCellSize, xll, yll, ASCNoDataValue: Double;
  Save_Cursor: TCursor;
  f: TextFile;
begin
  WriteToLogFile( 'Initialise TabstractESRIgrid (or descendant) from ASC-file.' );
  iResult := cUnknownError;
  Save_Cursor := Screen.Cursor;
  Try
    Screen.Cursor := crHourglass;
    Try
      {-Open ASC raster dataset}
      FileName := Trim( ExpandFileName( ASCfileName ) );
      WriteToLogFileFmt( 'Check existance of file [%s].' , [ ASCfileName ] );
      if not FileExists( ASCfileName ) then
        Raise Exception.CreateResFmt( @sE_ASC_File_does_not_exist, [ ASCfileName  ] );
      WriteToLogFileFmt( 'File [%s] exists.', [ ASCfileName ] );

      AssignFile( f, ASCfileName ); Reset( f );
      WriteToLogFileFmt( 'File [%s] opened.', [ ASCfileName ] );

      {-Read ASC heading}
      if not ReadASCheading( f, iNcols, iNrows, xll, yll, iCellSize, ASCNoDataValue ) then
        Raise Exception.CreateResFmt( @sE_Couldnot_read_ASC_heading, [ASCfileName] );

      Create( iNRows, iNCols, iResult, AOwner );
      CellSize := iCellSize;
      xMin := xll;
      yMin := yll;
      xMax :=  xMin + iNcols * iCellSize;
      yMax :=  yMin + iNrows * iCellSize;
      FileName := ExpandFileName( AnsiString( JustName( AscfileName ) ) );

      WriteToLogFile( 'Allocating data...' );
      for i:=1 to NRows do begin
        if not ReadRowFromTextFile( f, i, ASCNoDataValue ) then
          raise Exception.CreateFmt('Cannot Read row [%d] from ASC file.', [i] );
      end;
      CloseFile( f );
      WriteToLogFile( 'Done.' );

      WriteCharacteristicsToLogFile;
      iResult := cNoError;

    Finally
      Screen.Cursor := Save_Cursor;
      Try
        GridIOExit;
      Except
      end;
    end;
  Except
    On E: E_Error_Allocating_Memory_For_TabstractESRIgrid_Or_descendant do begin
      HandleError( E.Message, false );
    end;
    On E: Exception do begin
      HandleError( E.Message, true );
    end;
  end;
end; {-Constructor TabstractESRIgrid.InitialiseFromESRIGridFile}

Function TabstractESRIgrid.GetWindowRowFromChannel( const Channel, RowNr: Integer ): Boolean;
begin
  Result := false;
end;

Function TabstractESRIgrid.PutWindowRowToChannel( const Channel, RowNr: Integer ): Boolean;
begin
  Result := false;
end;

Function TabstractESRIgrid.ReadRowFromTextFile( var f: TextFile;
  const RowNr: Integer; const ASCNoDataValue: Double ): Boolean;
begin
  Result := false;
end;

begin
  with FormatSettings do begin {-Delphi XE6}
    Decimalseparator := '.';
  end;
end.
