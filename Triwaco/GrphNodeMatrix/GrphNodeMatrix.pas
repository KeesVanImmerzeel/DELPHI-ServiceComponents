unit GrphNodeMatrix;

interface

uses
  Classes, DUtils,
  LargeArrays;

type
  PGrphNodeMatrix = ^TGrphNodeMatrix;
  TGrphNodeMatrix = class(TDoubleMatrix)
  private
    { Private declarations }
    MaxAquiferNr,                {-Aquifernrs van 0 tot MaxAquiferNr}
    AantalPeilbuizen,
    RegelNrOfHeaders: Integer;
    AantalTijdstippen: LongInt;
    Headers: TStringList;
    GrphNodeData: TDoubleMatrix;
    DateAndTimeStamp: TDateTime;
     {FileAge(const FileName: string): Integer
     FileGetDate(Handle: Integer): Integer;}
    Function IsGeldigPeilbuisNr( const PeilbuisNr: Integer ): Boolean;
    Function IsGeldigAquiferNr( const AquiferNr: LongInt ): Boolean;
    Function GetPeilbuisNr( const PeilbuisID: String; var PeilbuisNr: Integer ): Boolean;
  protected
    { Protected declarations }
  public
    { Public declarations }
    Constructor InitFromOpenedTextFile( var f: TextFile;
      AOwner: TComponent; var Initiated: Boolean );
    Procedure SetDateAndTimeStamp( const aFileName: String );
    Function GetDateAndTimeStamp: TDateTime;

    Function GrphNodeDataIsRead: Boolean;

    {-Roep ReadGrphNodeData alleen na TGrphNodeMatrix.InitFromOpenedTextFile
      om de GrphNodeData matrix te vullen.
      Als Length(SelectedTimes)=0, dan worden de gegevens van ALLE tijden gelezen}
    Function ReadGrphNodeData( var f: TextFile; const SelectedTimes: TarrayOfDouble;
      AOwner: TComponent ): Boolean;
    Procedure TrashGrphNodeData;

    Function IsGeldigTijdstipNr( const TijdstipNr: LongInt ): Boolean;
    Function GetNrOfAquifers: Integer;
    Function GetAantalPeilbuizen: Integer;

    Function GetPeilbuisID( const PeilbuisNr: Integer ): String;
    Function GetAantalTijdstippen: LongInt;

    Function GetTijd( const TijdstipNr: LongInt ): Double;
    Function GetWaarneming( const TijdstipNr, PeilbuisNr, AquiferNr: LongInt ): Double; Overload;
    Function GetWaarneming( const TijdstipNr, AquiferNr: LongInt; const PeilbuisID: String ): Double; Overload;

    Destructor Done;
  published
    { Published declarations }
  end;

const
  cGraphNodeNoData = -99999;

procedure Register;

implementation

uses
  Sysutils, Math,
  uError, OPWstring, xyTable;

{-Procedures, functies --------------------------------------------------------}

Type
  EErZijnGeenLeesbareGegevensAanwezig = class( Exception );

Resourcestring
    sErZijnGeenLeesbareGegevensAanwezig =
      'Er zijn geen (leesbare) waarnemingen aanwezig.';

procedure Register;
begin
  RegisterComponents('Triwaco', [TGrphNodeMatrix]);
end;

Function LeesGetaluitLine( const Line: String; const i: Integer;
  var LeesFout: Boolean ): Double;
const
  WordDelims: CharSet = [','];
var
  S: String;
  Len: Integer;
begin
  Result := cGraphNodeNoData; Leesfout := True;
  S := Trim( ExtractWord( i, Line, WordDelims, Len ) );
  if ( Len > 0 ) then begin
    Try
      Result := StrToFloat( S );
    Except
      Result := cGraphNodeNoData;
      Exit;
    end;
    Leesfout := false;
  end;
end; {-Function LeesGetaluitLine}

{-TGrphNodeMatrix -------------------------------------------------------------}

Procedure TGrphNodeMatrix.SetDateAndTimeStamp( const aFileName: String );
begin
  DateAndTimeStamp := FileDateToDateTime( FileAge( aFileName ) );
end;

Function TGrphNodeMatrix.GetDateAndTimeStamp: TDateTime;
begin
  Result := DateAndTimeStamp;
end;

Function TGrphNodeMatrix.GetPeilbuisNr( const PeilbuisID: String; var PeilbuisNr: Integer ): Boolean;
var
  i: Integer;
begin
  Result := False;
  PeilbuisNr := -1;
  i := 1;
  Repeat
    if ( GetPeilbuisID( i ) = PeilbuisID ) then begin
      Result := true;
      PeilbuisNr := i;
    end else
      Inc( i );
  Until Result or ( i > GetAantalPeilbuizen );
end;

Function TGrphNodeMatrix.GetNrOfAquifers: Integer;
begin
  Result := MaxAquiferNr;
end;

Function TGrphNodeMatrix.GrphNodeDataIsRead: Boolean;
begin
  Result := ( GrphNodeData <> nil );
end;

Function TGrphNodeMatrix.ReadGrphNodeData( var f: TextFile;
  const SelectedTimes: TarrayOfDouble; AOwner: TComponent ): Boolean;
var
  i, j, AantalTeLezenKolommen, k: LongInt;
  Line: String;
  NrOfRecords, SelectedRecNr, RecordNr: LongInt;
  eenGetal, EenTijd: Double;
  Leesfout, ReadAllRecords, ReadDataAtSelectedTimesOnly: Boolean;
  GNtimeRecNrRelation: TxyTable;

  Function GetSelectedRecNr( const SelectedTimeIndex: LongInt ): LongInt;
  begin
    Result := Round( GNtimeRecNrRelation.EstimateY( SelectedTimes[ SelectedTimeIndex ], FrWrd ) );
    Result := Min( Max( Result, 1 ), NrOfRecords );
  end;

begin
  Result := false;
  TrashGrphNodeData;
  Try
    {-Lees de tijdstippen en de stijghoogten}
    WriteToLogFile( 'Lees GrphNodeData.' );
    AantalTeLezenKolommen := ( GetNrOfAquifers+1 ) * GetAantalPeilbuizen + 1;

    {-Bepaal AantalTijdstippen}
    AantalTijdstippen := 0;
    ReadAllRecords := ( Length( SelectedTimes ) = 0 );
    ReadDataAtSelectedTimesOnly := not ReadAllRecords;
    NrOfRecords := 0; {-Bepaal eerst aantal records in graphnode output}
    {$I-} Reset( f ); {$I+}
    if ( IOResult <> 0 ) then
      Raise Exception.Create( 'Could not reset graphnode.out' );
    WriteToLogFile( 'HeaderLines...' );
    for i:=1 to RegelNrOfHeaders do begin
      Readln( f, Line );
      WriteToLogFile( Line );
    end;
    Leesfout := false;
    Repeat
      Try
        Readln( f, Line );
        eenGetal := LeesGetaluitLine( Line, 1, LeesFout );
        WriteToLogFileFmt( 'Line="%s".', [Line] );
        WriteToLogFileFmt( '%d-ste getal = %g', [NrOfRecords+1, EenGetal] );
      Except
        Leesfout := true;
        WriteToLogFileFmt( 'Leesfout: Line = [%s]; NrOfRecords= [%d]', [Line, NrOfRecords] );
      end;
      if ( not Leesfout ) then begin
        WriteToLogFileFmt( 'Record [%d] gelezen. ', [NrOfRecords] );
        Inc( NrOfRecords );
      end;
    Until ( EOF( f ) ) or Leesfout;
    WriteToLogFileFmt( 'NrOfRecords in GraphNode.out= %d', [NrOfRecords] );
    if ( NrOfRecords <= 0 ) then
      Raise Exception.CreateFmt( 'NrOfRecords in graphnode.output <= 0: [%d]',  [NrOfRecords] );
    if ReadAllRecords then
      AantalTijdstippen := NrOfRecords
    else
      AantalTijdstippen := Length( SelectedTimes );
    WriteToLogFileFmt( 'Aantal tijdstippen: %d.', [GetAantalTijdstippen] );

    {-Omdat in graphnode.out niet altijd precies de gespecificeerde tijdstippen
      uit model.ini voorkomen, moet het dichtstbijzijnde tijdstip worden gevonden.
      Gebruik hiervoor GNtimeRecNrRelation}
    if ReadDataAtSelectedTimesOnly then begin
      GNtimeRecNrRelation := TxyTable.Create( NrOfRecords, self );
      Reset( f );
      for i:=1 to RegelNrOfHeaders do
        Readln( f, Line );
      for i:=1 to NrOfRecords do begin
        Readln( f, Line );
        GNtimeRecNrRelation.SetXY( i, LeesGetaluitLine( Line, 1, LeesFout ), i );
      end;
      WriteToLogFile( 'GNtimeRecNrRelation created.' );
      //GNtimeRecNrRelation.WriteToTextFile( lf );
    end;

    {-Initialiseer nu de GrphNodeData-matrix en vul met gegevens}
    GrphNodeData := TDoubleMatrix.CreateF( GetAantalTijdstippen,
      AantalTeLezenKolommen, cGraphNodeNoData, self );
    Reset( f );
    for i:=1 to RegelNrOfHeaders do
      Readln( f, Line );
    Leesfout := false;
    i := 1;
    k := 0;
    RecordNr := 1;
    SelectedRecNr := 1;
    if ReadDataAtSelectedTimesOnly then begin
      SelectedRecNr := GetSelectedRecNr( k );
    end;
    Repeat
      EenTijd := 0;
      Try
        Readln( f, Line );
        EenTijd := LeesGetaluitLine( Line, 1, LeesFout );
      Except
        Leesfout := true;
      end;
      if ( not Leesfout ) then begin
        if ReadAllRecords or
          ( ReadDataAtSelectedTimesOnly and ( RecordNr = SelectedRecNr ) ) then begin
          GrphNodeData[ i, 1 ] := EenTijd;
          for j:=2 to AantalTeLezenKolommen do begin
            eenGetal := LeesGetaluitLine( Line, j, LeesFout );
            if ( not Leesfout ) then begin
              GrphNodeData[ i, j ] := eenGetal;
            end else
              Raise Exception.Create( 'Error reading GrphNodeData.' );
          end; {-for j}
          Inc( i );
          if ReadDataAtSelectedTimesOnly then begin
            Inc( k ); SelectedRecNr := GetSelectedRecNr( k );
          end;
        end;
        Inc( RecordNr );
      end; {-if not Leesfout}
    Until ( EOF( f ) ) or Leesfout;

    if ReadDataAtSelectedTimesOnly then begin
      Try
        GNtimeRecNrRelation.Free;
      except
      end;
    end;

    //GrphNodeData.WriteToTextFile( lf, #9 );
    Result := true;
    WriteToLogFile( 'GrphNodeData is initiated.' );
  except
    On E: Exception do begin
      HandleError( E.Message, true );
    end;
  end; {-Try}
end; {-Procedure TGrphNodeMatrix.ReadGrphNodeData}

Destructor TGrphNodeMatrix.Done;
begin
  Try
    Headers.Free;
    GrphNodeData.Free;
  Except
  end;
end;

Function TGrphNodeMatrix.GetAantalPeilbuizen: Integer;
begin
  Result := AantalPeilbuizen;
end;

Function TGrphNodeMatrix.GetAantalTijdstippen: LongInt;
begin
  Result := AantalTijdstippen;
end;

Function TGrphNodeMatrix.IsGeldigPeilbuisNr( const PeilbuisNr: Integer ): Boolean;
begin
  Result := ( PeilbuisNr > 0 ) and ( PeilbuisNr <= GetAantalPeilbuizen );
end;

Function TGrphNodeMatrix.GetPeilbuisID( const PeilbuisNr: Integer ): String;
var
  i: Integer;
begin
  if IsGeldigPeilbuisNr( PeilbuisNr ) then begin
    i := ( PeilbuisNr - 1 ) * ( MaxAquiferNr + 1 );
    Result := copy( Headers[ i ], 1, 6 );
  end else
    Result := '';
end;

Function TGrphNodeMatrix.IsGeldigTijdstipNr( const TijdstipNr: LongInt ): Boolean;
begin
  Result := ( TijdstipNr > 0 ) and ( TijdstipNr <= GetAantalTijdstippen );
end;

Function TGrphNodeMatrix.GetTijd( const TijdstipNr: LongInt ): Double;
begin
  if ( GrphNodeDataIsRead and IsGeldigTijdstipNr( TijdstipNr ) ) then
    Result := GrphNodeData[ TijdstipNr, 1 ]
  else
    Result :=0;
end;

Function TGrphNodeMatrix.IsGeldigAquiferNr( const AquiferNr: LongInt ): Boolean;
begin
  Result := ( AquiferNr > -1 ) and ( AquiferNr <= GetNrOfAquifers );
end;

Procedure TGrphNodeMatrix.TrashGrphNodeData;
begin
  Try
    GrphNodeData.Free;
    GrphNodeData := nil;
  Except
  end;
end;

Function TGrphNodeMatrix.GetWaarneming( const TijdstipNr, PeilbuisNr,
  AquiferNr: LongInt ): Double;
var
  i, j: LongInt;
begin
  if GrphNodeDataIsRead and
     IsGeldigTijdstipNr( TijdstipNr ) and
     IsGeldigPeilbuisNr( PeilbuisNr ) and
     IsGeldigAquiferNr( AquiferNr ) then begin
    i := TijdstipNr;
    j := 2 + AquiferNr + ( PeilbuisNr - 1 ) * ( MaxAquiferNr + 1 );
    Result := GrphNodeData[ i, j ];
  end else
    Result := cGraphNodeNoData;
end;

Function TGrphNodeMatrix.GetWaarneming( const TijdstipNr, AquiferNr: LongInt; const PeilbuisID: String ): Double;
var
  PeilbuisNr: LongInt;
begin
  Result := cGraphNodeNoData;
  if not GetPeilbuisNr( PeilbuisID, PeilbuisNr ) then
    Exit;
  Result := GetWaarneming( TijdstipNr, PeilbuisNr, AquiferNr );
end;

Constructor TGrphNodeMatrix.InitFromOpenedTextFile( var f: TextFile;
      AOwner: TComponent; var Initiated: Boolean );
var
  Line, S: String;
  Found: Boolean;
  i, Len, AquiferNr, RegelNr: LongInt;
const
  WordDelims: CharSet = ['"',','];

begin
  Initiated := False;
  WriteToLogFile( 'Trying to initialise GrphNodeMatrix.' );

  DateAndTimeStamp := now;
  {Writeln( lf, Format( 'DateAndTimeStamp = [%s]', [DateTimeToStr(DateAndTimeStamp)] );}

  Try
    TrashGrphNodeData;
    {-Kijk of het bestandstype juist is a.d. hand van label}
    Found   := false;
    RegelNr := 0;
    While ( ( not Found ) and ( not EOF( f ) ) ) do begin
      Readln( f, Line ); Inc( RegelNr );
      Found := ( Pos( '"Time series output program FLAIRS"', Line ) = 1 );
    end;
    if ( not Found ) then
      Raise Exception.Create( 'Error: label "Time series output program FLAIRS" is not encountered in file "GRAPHNODE.OUT".' );

    {-Zoek en lees regel met Labels}
    Found := false;
    While ( ( not Found ) and ( not EOF( f ) ) ) do begin
      Readln( f, Line ); Inc( RegelNr );
      Found := ( Pos( '     "TIME","', Line ) = 1 );
    end;
    if ( not Found ) then
      Raise Exception.Create( 'Error: label "TIME"," is not encountered in file "GRAPHNODE.OUT".' );

    RegelNrOfHeaders := RegelNr;

    {-Lees Headers}
    WriteToLogFileFmt( 'Lees Headers in regel: %d', [RegelNr] );
    Headers := TStringList.Create;
    i := 0;
    Repeat
      S := Trim( ExtractWord( i+1, Line, WordDelims, Len ) );
      {Writeln( lf, 'S=[', S, ']' );}
      if ( S <> 'TIME' ) and ( S <> '' ) and ( S <> ',' ) then
        Headers.Add( S );
      if ( Len > 0 ) then
        Inc( i );
    Until ( Len = 0 );
    {Headers.SaveToFile( 'c:\tmp.txt' );}
    WriteToLogFileFmt( '%d Headers gelezen.', [Headers.Count] ); {Headers.SaveToFile( 'tmp.txt' );}

    if ( Headers.Count = 0 ) then
      Exception.Create( 'No data in file.' );

    {-Bepaal het maximale aquifernummer}
    MaxAquiferNr := -1;
    i := 0;
    Found := false;
    Repeat
      Try
        AquiferNr := StrToInt( Copy( Headers[ i ], 8, 2 ) );
      Except
        Raise EConvertError.Create( 'Error reading number.' );
      end;
      if ( AquiferNr > MaxAquiferNr ) then begin
        MaxAquiferNr := AquiferNr;
      end else begin
        Found := true;
      end;
      Inc( i );
    Until Found or ( i = Headers.Count-1 );
    WriteToLogFileFmt( 'MaxAquiferNr = %d', [MaxAquiferNr] );

    {if ( Headers.Count mod ( MaxAquiferNr + 1 ) ) <> 0 then
      Raise Exception.Create( 'Er ontbreken 1- of meerdere reeksen van peilbuizen.' );}

    AantalPeilbuizen := Headers.Count div ( MaxAquiferNr + 1 );
    WriteToLogFileFmt( 'AantalPeilbuizen= %d.', [GetAantalPeilbuizen] );

    for i:=1 to GetAantalPeilbuizen do
      WriteToLogFileFmt( 'Peilbuis %d: ID= %d', [i, GetPeilbuisID( i )] );

    {-Tel het aantal tijdstippen}
    AantalTijdstippen := 0;
    {Leesfout := false;
    Try
      Readln( f, Line );
      eenStijghoogte := LeesGetaluitLine( Line, 2, LeesFout );
    Except
      Leesfout := true;
    end;
    if ( not Leesfout ) then begin
      Inc( AantalTijdstippen );
    end;

    Writeln( lf, 'Aantal tijdstippen: ', GetAantalTijdstippen );
    if ( GetAantalTijdstippen = 0 ) then
      Raise EErZijnGeenLeesbareGegevensAanwezig.Create( 'Er zijn geen (leesbare) waarnemingen aanwezig.' );}

    {-Lees de tijdstippen en de stijghoogten}
    {if ( not HeadersOnly ) then begin
      if ( not ReadGrphNodeData( f, lf, self ) ) then begin
        Raise Exception.Create( 'Error reading GrphNodeData.' );
      end;
    end else begin
      Writeln( lf, 'Headers of GrphNodeData are initiated.' );
    end;} {-if ( not HeadersOnly )}

  Except
    On E: EErZijnGeenLeesbareGegevensAanwezig do begin
      HandleError( sErZijnGeenLeesbareGegevensAanwezig, false );
      Exit;
    end;
    On E: Exception do begin
      HandleError( E.Message, true );
      TrashGrphNodeData;
      Exit;
    end;
    On E: EConvertError do begin
      HandleError( E.Message, true );
      TrashGrphNodeData;
      Exit;
    end;
  end;

  Initiated := True;
  WriteToLogFile( 'GrphNodeMatrix is initiated.' );
end;

end.
