unit uTTrishellDataSet;

{-This units exports TTrishellDataSet-components  (ini-files in Trishell)}

interface

uses
  SysUtils, Classes, IniFiles,
  GrphNodeMatrix;

const
  cInitialData    = 201;
  cGrid           = 202;
  cCalibration    = 203;
  cScenario       = 204;
  cFinal          = 205;
  cUnsaturated    = 300;
  cTransient      = 301;
  cPathLine       = 302;
  NotAvailableStr = 'n/a';

const
 cDefaultVersion = '-';
 cDefaultHeader = '-';
 cDefaultProjectID = '-';
 cDefaultDescription = '-';
 cDefaultDatasetName = '-';
 cDefaultDataSetID = '-';

type
  TTrishellDataSetType = ( InitialData, Grid, Calibration, Scenario, Final,
    Unsaturated, Transient, PathLine, Unknown );
  TProgramGroup = ( DefaultProgGroup, ModFlow );

  THeader = record
    DescriptionStr,
    NameStr,
    IDStr:
      String;
    TrishellDataSetType:
      TTrishellDataSetType;
  end;

  TFiles = record
    InputFileNameStr,
    OutputFileNameStr,
    PrintFileNameStr,
    LogFileNameStr,
    TIMfileNameStr:
      String;
  end;

  TDataSets = record
    RelativePathOfGridDataSet,
    RelativePathOfBaseDataSet,
    RelativePathOfUnsaturatedDataSet:
      String;
  end;

  TFlairs = record
    Aquifers, {-number of aquifers (Naq)}
    NrOfSubAreasForWaterBalancCalculations, {-number of sub-areas for water balance calculation (Nsar)}
    TopSystem,
    Inner,
    Outer,
    Print: Integer;
    Phreatic, {- Phreatic calculations (Iffr)}
    Transient,  {- Transient calculations (Ifss)}
    SaltFreshInterface: Boolean;  {- Variable density or salt / fresh water interface (Ifsf)}
    Relax,   {- Relaxation factor for non-linear iterations (Rrlax) }
    Converge: Double;
  end;

{-TOpenSection ----------------------------------------------------------------}

  {-Ident-strings and corresponding values of a section in an ini-file}
  POpenSection = ^TOpenSection;
  TOpenSection = class( TComponent )
  private
    { Private declarations }
    IdentStringList,
    ValueStringList:
      TStringList;
  protected
    { Protected declarations }
  public
    { Public declarations }
    SectionStr:
      String;
    Constructor CreateFromIniFile( const iSectionStr: String; var fini : TiniFile;
      var iError: Integer; AOwner: TComponent );
    Function NrOfIdentifiers: LongInt;
    Function GetValueOfIdentifier( const aIdentifier: String ): String;
    Destructor Destroy; Override;
  published
    { Published declarations }
  end;

  ESectionCouldNotBeInitialised = class( Exception );

Resourcestring
    sSectionCouldNotBeInitialised = 'Section [%s] could not be initialised.';

{-TFliFileDataSet -------------------------------------------------------------}

Type
  TparNameChars = String[2];
  PFliFileDataSet = ^TFliFileDataSet;
  TFliFileDataSet = class( TComponent )
  private
    Function GetIndexOfTriwacoParName( const TriwacoParNameStr: string;
      var index: integer ): Boolean;
  protected
  public
    IDStr: String;
    Flairs: TFlairs;
    TriwacoParName,
    ParFileName,
    UserDefinedParName: TStringList;
    FullPathNameOfFliFile: String;
    Constructor CreateFromFliFile( const iFliFileName: String;
      var iError: Integer; AOwner: TComponent );
      function GetMaxParNameIndex( const ParName: TparNameChars; var iError:
        LongInt ): LongInt;
      {-MaxParNameIndex: Maximale waarde die voorkomt i.d. naam van parameter.
        Als deze waarde om de 1-of andere reden niet is te bepalen (bijv. als
        het type niet voorkomt in de IdentStringList), dan Result -1 }
    Function WriteToTextFile( var f: TextFile; var iError: LongInt ): Boolean; Virtual;
    Function FullPathNameOfParFile( const TriwacoParNameStr: string ): String; Virtual;
    Destructor Destroy; Override;
  published
  end;

  EFliFileCouldNotBeOpened = class( Exception );
  EErrorWritingFliFileDataSetToTextfile = class( Exception );
  ECouldNotDetermineMaxParNameIndex = class( Exception );

Resourcestring
    sFliFileCouldNotBeOpened = 'Fli-file could not be opened.';
    sInfoFromFliFileCouldNotBeRead = 'Info from fli-file: "%s" could not be read.';
    sCouldNotDetermineMaxParNameIndex =
      'Could not determine MaxParNameIndex of parameter: "%s".';
    sErrorWritingFliFileDataSetToTextfile = 'Error writing FliFileDataSet to textfile';

{-TTrishellDataSet ------------------------------------------------------------}

Type
  PTrishellDataSet =^TTrishellDataSet;
  TTrishellDataSet = class(TComponent)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    ProgramGroup: TProgramGroup;
    VersionStr,
    FullPathNameOfIniFile:
      String;
    Header:
      THeader;
    Flairs:
      TFlairs;
    Files:
      TFiles;
    DataSets:
      TDataSets;
    Parameters_Section,
    Expressions_Section,
    Result_Section: TOpenSection;
    Constructor CreateFromIniFile( Const IniFileName: String; var iError: Integer;
      AOwner: TComponent );
    Function FullPathOfGridDataSet: String; Virtual;

    Function FullPathOfGridFileName: String; Virtual;       {-grid.teo}
    Function FullPathOfOutputFileName: String; Virtual;     {-flairs.flo}

    Function GetID: String; Virtual;
    Function GetDescription: String; Virtual;
    Function HasBaseDataSet: Boolean; Virtual;
    Function BaseDataSet: String; Virtual;
    Function GetTrishellDataSetType: TTrishellDataSetType; Virtual;
    Function GetNrOfAquifers: Integer;
  published
    { Published declarations }
  end;

  EErrorCreatingOpenSection = class( Exception );

Resourcestring
  sErrorCreatingOpenSection = 'Error creating OpenSection "%s".';
  sTrishellDataSetCouldNotBeInitialisedFromFile =
    'TrishellDataSet could not be initialised from file: "%s"';

{-TPathLineDataSet ------------------------------------------------------------}

Type

  PPathLineDataSet = ^TPathLineDataSet;
  TPathLineDataSet = class( TTrishellDataSet )
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
  published
    { Published declarations }
    Constructor CreateFromIniFile( Const IniFileName: String; var iError: Integer; AOwner: TComponent );
  end;

  EIsNotATraceDataSet = class( Exception );
  EErrorReadingTraceDataSet = class( Exception );

Resourcestring
  sIsNotATraceDataSet = 'File: "%s" is not a Trace dataset.';
  sErrorReadingTraceDataSet = 'Info from file: "%s" could not be read.';

{-TTransientDataSet -----------------------------------------------------------}

Type

  PTransientDataSet = ^TTransientDataSet;
  TTransientDataSet = class( TTrishellDataSet )
  private
    { Private declarations }
    GrphNodeMatrix: PGrphNodeMatrix;
    TimeSteps_Section: TOpenSection;
    StartTime, EndTime: TDateTime;
    GraphNodeNamStrings, PrimitiveGraphNodePeilbuisIDs: TStringList;
    RelativePathOfGraphNodeUngFile: String;
    Function FullPathNameOfGraphNodeUngFileName: String;
{Time step=30
dhmax=0.1
dtinitial=0.1
GraphNodeUng=.}
  protected
    { Protected declarations }
    Function GetGrphNodeFileName: String;
  public
    { Public declarations }
    { Published declarations }
    Constructor CreateFromIniFile( Const IniFileName: String; var iError: Integer;
      AOwner: TComponent );
    Function ReadGrphNodeData( const OnlyAtSpecifiedOutputTimes: Boolean;
      AOwner: TComponent ): Boolean;

    Function HasGrphNodeData: Boolean;

    Function GetPeilbuisID( const PeilbuisNr: Integer ): String;
    Function GetAantalPeilbuizen: Integer;

    Function GetStartTime: TDateTime;
    Function GetEndTime: TDateTime;
    Function GetNrOfSpecifiedOutputTimes: LongInt;
    Function GetSpecifiedOutputTime( const aOutputTimeIndex: LongInt ): TDateTime;
    Function GetPreviousOutputTime( const aOutputTime: TDateTime ): TDateTime;
    Function IsSpecifiedOutputTime( const aOutputTime: TDateTime ): Boolean;

    Function GetDateAndTimeStampOfGrphNodeFile: TDateTime;
    Function GetNrOfOutputTimesInGrphNodeMatrix: Integer;
    Function GetOutputDateTimeOfGrphNodeMatrix( const TijdstipNr: LongInt ): TDateTime;

    Function GetGrphNodeValue( const GrphNodeTijdstipNr, AquiferNr: LongInt;
      const PeilbuisID: String ): Double;

    Procedure TrashGrphNodeData;

    Destructor Destroy; Override;
  published
  end;

  EIsNotATransientDataSet = class( Exception );
  EErrorReadingTransientDataSet = class( Exception );



Resourcestring
  sIsNotATransientDataSet = 'File: "%s" is not a Trace dataset.';
  sErrorReadingTransientDataSet = 'Info from file: "%s" could not be read.';

{-Functions, procedures--------------------------------------------------------}

Function ReadTrishellDataSetType( Const IniFileName: String;
    var iError: Integer ): TTrishellDataSetType;

Function Tri4_ReadFullPathNameOfGridFileName( Const IniFileName: TFileName;
    var iError: Integer ): TFileName;

Function Tri4_ReadFullPathNameOfBaseDataSet( Const IniFileName: TFileName;
    var iError: Integer ): TFileName;

Function Tri4_IsTrishellModelIniFile( Const IniFileName: TFileName ): Boolean;

procedure Register;

implementation

Uses
  Dialogs, Math,
  uError, OpWString, LargeArrays;

const
  cError = -999999;
  WordDelimPoint: CharSet = ['.']; {-tbv Triwaco 4.0}

procedure Register;
begin
  RegisterComponents('Triwaco', [TTrishellDataSet]);
  RegisterComponents('Triwaco', [TOpenSection]);
  RegisterComponents('Triwaco', [TFliFileDataSet]);
end;

Function TrishellDataSetType( const i: Integer ): TTrishellDataSetType;
begin
  Case i of
    cInitialData : TrishellDataSetType := InitialData;
    cGrid        : TrishellDataSetType := Grid;
    cCalibration : TrishellDataSetType := Calibration;
    cScenario    : TrishellDataSetType := Scenario;
    cFinal       : TrishellDataSetType := Final;
    cUnsaturated : TrishellDataSetType := Unsaturated;
    cTransient   : TrishellDataSetType := Transient;
    cPathLine    : TrishellDataSetType := PathLine;
  else
    TrishellDataSetType := Unknown;
  end; {-case}
end;

Function ReadTrishellDataSetType( Const IniFileName: String;
      var iError: Integer ): TTrishellDataSetType;
var
  FullPathNameOfIniFile: String;
  fini : TiniFile;
  RegimeStr: String; {Triwaco 4.0}
begin
  iError := cUnknownError;
  Try
    FullPathNameOfIniFile := ExpandFileName( IniFileName );
    fini := TIniFile.Create( FullPathNameOfIniFile );
    Result := TrishellDataSetType( fini.ReadInteger( 'Header', 'Type', cError ) );
    {Triwaco 4.x}
    RegimeStr := fini.ReadString( 'Header', 'Regime', '' );
    if RegimeStr = 'Transient' then
      Result := TrishellDataSetType( cTransient );
    fini.Free;
    iError := cNoError;
  except
    Result := Unknown;
  end; {-try}
end; {-Function GetTrishellDataSetType}

{Read grid filename from 'model.ini' (Triwaco 4.0)}
Function Tri4_ReadFullPathNameOfGridFileName( Const IniFileName: TFileName;
    var iError: Integer ): TFileName;
var
  FullPathNameOfIniFile, S: String;
  fini : TiniFile;
  Len: Integer;
Const
  WordDelims: CharSet = ['.'];
begin
  iError := cUnknownError; Result := '';
  Try
    FullPathNameOfIniFile := ExpandFileName( IniFileName );
    fini := TIniFile.Create( FullPathNameOfIniFile );
    // Find path to Triwaco grid folder
    S := fini.ReadString( 'Datasets', 'Grid', 'Error' );
    if ( S = 'Error' ) then
      raise Exception.Create('Invalid model.ini file');
    S := ExtractFilePath( ExtractFileDir( ExcludeTrailingPathDelimiter(IniFileName) ) ) +
                 ExtractWord( 2, S, WordDelims, Len );
    if ( Len <=0 ) then
      raise Exception.Create('Invalid model.ini file');
    Result := S + '\grid.teo'; ;
    fini.Free;
    iError := cNoError;
  except
  end; {-try}
end; {-Function Tri4_ReadFullPathNameOfGridFileName}

Function Tri4_ReadFullPathNameOfBaseDataSet( Const IniFileName: TFileName;
    var iError: Integer ): TFileName;
var
  FullPathNameOfIniFile, S: String;
  fini : TiniFile;
  Len: Integer;
Const
  WordDelims: CharSet = ['.'];
begin
  iError := cUnknownError; Result := '';
  Try
    FullPathNameOfIniFile := ExpandFileName( IniFileName );
    fini := TIniFile.Create( FullPathNameOfIniFile );
    // Find path to Triwaco grid folder
    S := fini.ReadString( 'Datasets', 'Base', 'Error' );
    if ( S = 'Error' ) then
      raise Exception.Create('Invalid model.ini file');
    S := ExtractFilePath( ExtractFileDir( ExcludeTrailingPathDelimiter(IniFileName) ) ) +
                 ExtractWord( 2, S, WordDelims, Len );
    if ( Len <=0 ) then
      raise Exception.Create('Invalid model.ini file');
    Result := S;
    fini.Free;
    iError := cNoError;
  except
  end; {-try}
end;

Function Tri4_IsTrishellModelIniFile( Const IniFileName: TFileName ): Boolean;
var
  iError: Integer;
begin
  Result := ( ReadTrishellDataSetType( IniFileName, iError ) <> Unknown );
end;

{-TFliFileDataSet -------------------------------------------------------------}

Constructor TFliFileDataSet.CreateFromFliFile( const iFliFileName: String;
  var iError: Integer; AOwner: TComponent );
var
  f: TextFile;
  Line: String;
  i1, i2, i3, dummy: Integer;

  Procedure ReadParInfoSection;
  var
    TriwacoParNameStr, ParFileNameStr, UserDefinedParNameStr: String;
    Function IsEndLine( const aLine: string ): Boolean;
    var
      Line: String;
    begin
      Line := Trim( LowerCase( aLine ) );
      Result := ( ( Line = 'end' ) or ( Line = 'end of sources input' ) or
        ( Line = 'end of boundary input' ) or ( Line = 'end of river input' ) );
    end; {-Function IsEndLine}
    Function ParFileAndUserDefParNameAlreadyListed( const ParFileNameStr, UserDefinedParNameStr: String ): Boolean;
    var
      i : Integer;
    begin
      i := ParFileName.IndexOf( ParFileNameStr );
      if ( i > -1 ) then
        Result :=  ( UserDefinedParName.Strings[ i ] = UserDefinedParNameStr )
      else
        Result := false;
    end;
  begin
    while ( ( not EOF( f ) ) and ( not IsEndLine( Line ) )  ) do begin
      Readln( f, Line );
      if ( ( not IsEndLine( Line ) ) ) and ( not EOF( f ) ) then begin
        TriwacoParNameStr := Line; {TriwacoParName.Add( Line );}
        Readln( f, Line );
        if ( ( not IsEndLine( Line ) ) ) and ( not EOF( f ) ) then begin
          ParFileNameStr := Line; {ParFileName.Add( Line );}
          Readln( f, Line );
          if ( ( not IsEndLine( Line ) ) ) and ( not EOF( f ) ) then begin
            UserDefinedParNameStr := Line; {UserDefinedParName.Add( Line );}
            If not ParFileAndUserDefParNameAlreadyListed( ParFileNameStr, UserDefinedParNameStr ) then begin
              TriwacoParName.Add( TriwacoParNameStr );
              ParFileName.Add( ParFileNameStr );
              UserDefinedParName.Add( UserDefinedParNameStr );
            end; {-if}
          end;
        end; {-if}
      end; {-if}
    end;{-while}
  end; {-Procedure ReadParInfoSection;}

begin
  iError := cUnknownError;
  Try
    FullPathNameOfFliFile := ExpandFileName( iFliFileName );
    //WriteToLogFileFmt( 'Reading info from fli-file: "' + FullPathNameOfFliFile + '".' );
    WriteToLogFileFmt( 'Reading info from fli-file: "%s".',[FullPathNameOfFliFile] );
    {$I-}
    AssignFile( f, FullPathNameOfFliFile ); Reset( f );
    {$I+}
    if IOResult <> 0 then
      Raise EFliFileCouldNotBeOpened.CreateRes( @sFliFileCouldNotBeOpened );
    ParFileName        := TStringList.Create;
    UserDefinedParName := TStringList.Create;
    TriwacoParName     := TStringList.Create;

    Readln( f, IDStr );
    With Flairs do begin
      Readln( f, Aquifers, i1, i2, i3, dummy, NrOfSubAreasForWaterBalancCalculations, Relax );
      Phreatic := ( i1 > 0 );
      Transient := ( i2 > 0 );
      SaltFreshInterface := ( i3 > 0 );
    end;
    {Flairs.TopSystem}
    {Flairs.Inner}
    {Flairs.Outer}
    {Flairs.Print}
    {Flairs.Converge}

    {-Zoek begin van data-sets namen}
    repeat
      Readln( f, Line );
    until ( ( Trim( LowerCase( Line) ) = 'end of river input' ) or EOF( f ) );

    Line := '';
    ReadParInfoSection; Readln( f ); Readln( f );
    while ( not EOF( f ) ) do begin
      Readln( f ); Readln( f );
      Line := '';
      ReadParInfoSection;
    end;


    CloseFile( f );
    iError := cNoError;
    //WriteToLogFileFmt( 'Info from fli-file: "' + FullPathNameOfFliFile + '" is read.' );
    WriteToLogFileFmt( 'Info from fli-file: "%s" is read.', [FullPathNameOfFliFile] );
  except
    On E: Exception do begin
      HandleError(  E.Message, true);
      HandleError(  Format( sInfoFromFliFileCouldNotBeRead,
        [FullPathNameOfFliFile] ), false );
    end;
  end;{-except}
end; {-Constructor TFliFileDataSet}


function TFliFileDataSet.GetMaxParNameIndex( const ParName:
  TparNameChars; var iError: LongInt ): LongInt;
var
  i: LongInt;
begin
  iError := cUnknownError;
  Result := -1;
  Try
    //WriteToLogFileFmt( 'GetMaxParNameIndex of parameter: "' + ParName + '" from fli file: "' +
    //FullPathNameOfFliFile + '".');
    WriteToLogFileFmt( 'GetMaxParNameIndex of parameter: "%s" from fli file: "%s".', [ParName, FullPathNameOfFliFile] );
    for i:=0 to TriwacoParName.Count-1 do begin
      if Pos( ParName, TriwacoParName[ i ] ) = 1 then begin {-Parameter komt voor i.d. lijst}
        Try
          Result := Max( StrToInt( copy( TriwacoParName[ i ], 3,
            Length( TriwacoParName[ i ] ) ) ), Result );
        except
        end;
      end; {-if}
    end; {-for}
    iError := cNoError;
    //WriteToLogFileFmt( 'MaxParNameIndex of: ' + ParName + ' = ', Result );
    WriteToLogFileFmt( 'MaxParNameIndex of: %s = %g.', [ParName, Result] );
  except
    On E: Exception do begin
      Result := -1;
      HandleError(  E.Message, false );
      HandleError(  Format( sCouldNotDetermineMaxParNameIndex, [ParName] ),
        true );
    end;
  end;
end; {-function TFliFileDataSet.GetMaxParNameIndex}

Function TFliFileDataSet.GetIndexOfTriwacoParName( const TriwacoParNameStr: string;
  var index: integer ): Boolean;
var
  n: LongInt;
begin
  Result := false;
  index := 0; n := TriwacoParName.Count;
  repeat
    if ( index < n ) then
      Result := ( TriwacoParNameStr = TriwacoParName[ index ] );
    if not Result then
      Inc( index );
  until result or ( index = n );
end;

Function TFliFileDataSet.FullPathNameOfParFile( const TriwacoParNameStr: string ): String;
var
  InitDir: String;
  i: Integer;
begin
  InitDir := GetCurrentDir;
  Result := '';
  Try
    Try
      if GetIndexOfTriwacoParName( TriwacoParNameStr, i ) then begin
        ChDir( ExtractFileDir( FullPathNameOfFliFile ) );
        ChDir( ExtractFileDir( ExpandFileName( ParFileName[ i ] ) ) );
        Result := GetCurrentDir + '\' + ExtractFileName( ParFileName[ i ] );
      end;
    finally
      ChDir( InitDir );
    end;
  except
  end;
end; {-Function TFliFileDataSet.FullPathNameOfParFile}

Destructor TFliFileDataSet.Destroy;
begin
  Try
    TriwacoParName.free;
    ParFileName.free;
    UserDefinedParName.free;
    inherited Destroy;
  Except
  End;
end;

Function TFliFileDataSet.WriteToTextFile( var f: TextFile;
  var iError: LongInt ): Boolean;
var
  i: LongInt;
begin
  Result := false;
  iError := cUnknownError;
  Try
    WriteToLogFile( 'FliFileDataSet.WriteToTextFile' );
    for i:=0 to TriwacoParName.Count - 1 do begin
      Writeln( f, TriwacoParName[ i ] );
      Writeln( f, ParFileName[ i ] );
      Writeln( f, UserDefinedParName[ i ] );
    end;
    iError := cNoError;
    Result := true;
  Except
    On E: Exception do begin
      HandleError(  E.Message, true );
      HandleError(  sErrorWritingFliFileDataSetToTextfile, true );
    end;
  end;
end;

{-TOpenSection ----------------------------------------------------------------}

Constructor TOpenSection.CreateFromIniFile( const iSectionStr: String;
  var fini: TiniFile; var iError: Integer; AOwner: TComponent );
var
  i: LongInt;
  tmpValueStringList: TStringList;
  aFileName: String;

  Function GetValueStr( const Ident: String ): String;
  var
    i, Len, Index, Cnt: Integer;
    Found: Boolean;
    S: String;
  const
    WordDelims = (['=']);
  begin
    Result := ''; Found := false; i := 0;
    repeat
      if ( i <= tmpValueStringList.Count-1 ) then begin
        S := ExtractWord( 1, tmpValueStringList[ i ], WordDelims, Len );
        if ( ( Len > 0 ) and ( S = Ident ) ) then begin
          Found  := true;
          Index  := Length( Ident ) + 2;
          Cnt    := Length( tmpValueStringList[ i ] ) - Index + 1;
          Result := copy( tmpValueStringList[ i ], Index, Cnt );
        end; {-if}
      end; {-if}
      Inc( i );
    until ( Found or ( i = tmpValueStringList.Count ) );
  end; {-Function GetValueStr}

begin
  iError := cUnknownError;
  WriteToLogFileFmt( 'Initialising Section [%s].', [iSectionStr] );
  SectionStr := iSectionStr;
  Try
    IdentStringList := TStringList.Create;
    ValueStringList := TStringList.Create;
    tmpValueStringList := TStringList.Create;
    with fini do begin
      ReadSection ( SectionStr,  IdentStringList );
      ReadSectionValues( SectionStr, tmpValueStringList );
    end; {-with fini}
    for i:=0 to IdentStringList.Count-1 do begin
      WriteToLogFileFmt( 'Ident="%s".', [IdentStringList[ i ]] );
      ValueStringList.Add( GetValueStr( IdentStringList[ i ] ) );
      WriteToLogFileFmt( 'Value="%s".', [ValueStringList[ i ]] );
    end; {-for}
    tmpValueStringList.Free;
    iError := cNoError;
    WriteToLogFileFmt( 'Section [%s] initialised with %d values.',
      [iSectionStr, IdentStringList.Count] );

    {-Triwaco 4.0}
    if ( IdentStringList.Count = 1 ) and ( IdentStringList[ 0 ] = 'file' ) then begin
      {WriteToLogFileFmt( 'ValueStringList[ 0 ] = ' + ValueStringList[ 0 ] );}
      aFileName := ExtractFileDir( fini.FileName ) + '\' + ValueStringList[ 0 ];
      WriteToLogFileFmt( 'Reading values from file [%s].', [aFileName] );
      ValueStringList.LoadFromFile(  aFileName );    {ValueStringList.SaveToFile( 'valuestringlist.txt' );}
      IdentStringList.Clear;
      for i:=0 to ValueStringList.Count-1 do begin
        IdentStringList.Add( IntToStr( i+1 ) );
      end;
      {IdentStringList.SaveToFile( 'identstringlist.txt' );}
      WriteToLogFileFmt( 'Values read: %d.', [ValueStringList.Count-1] );
    end;

  except
    On E: Exception do begin
      HandleError(  E.Message, false );
      HandleError(  Format( sSectionCouldNotBeInitialised, [iSectionStr] ),
        true );
    end;
  end; {-except}
end;

Function TOpenSection.NrOfIdentifiers: LongInt;
begin
  Result := IdentStringList.Count;
end;

Function TOpenSection.GetValueOfIdentifier( const aIdentifier: String ): String;
var
  i: LongInt;
begin
  Result := '';
  i := IdentStringList.IndexOf( aIdentifier );
  if ( i > 0 ) then
    Result := ValueStringList.Strings[ i ];
end;

Destructor TOpenSection.Destroy;
begin
  Try
    IdentStringList.free;
    ValueStringList.free;
    Inherited Destroy;
  except
  end;
end;

{-TTrishellDataSet ------------------------------------------------------------}

Constructor TTrishellDataSet.CreateFromIniFile( Const IniFileName: String;
  var iError: Integer; AOwner: TComponent );
var
  fini : TiniFile;
  i, tmpError: LongInt;
  Len: Integer;

  Procedure SetProgramGroup;
  var
    BufTSDataSet: TTrishellDataSet;
    ProgramGroupStr, CurrentDirStr: String;
    iErrorTmp: LongInt;
  begin
    WriteToLogFile( 'Setting Program Group' );
    ProgramGroup := DefaultProgGroup;
    ProgramGroupStr := fini.ReadString( 'Grid', 'Program group', NotAvailableStr );
    if ProgramGroupStr = 'ModFlow' then  begin
      ProgramGroup := ModFlow;
    end else begin
      {-Uitgeschakeld: lijkt niet te werken}
      {if ( DataSets.RelativePathOfGridDataSet <> NotAvailableStr ) then begin
        Try
          CurrentDirStr := GetCurrentDir;
          ChDir( ExtractFileDir( FullPathNameOfIniFile ) );
          BufTSDataSet :=
            TTrishellDataSet.CreateFromIniFile( '..\' +
            DataSets.RelativePathOfGridDataSet + '\Model.ini', lf, iErrorTmp,
            AOwner );
          if iErrorTmp = cNoError then
            ProgramGroup := BufTSDataSet.ProgramGroup;
          BufTSDataSet.Free;
          ChDir( CurrentDirStr);
        except
        end;
      end;}
    end;
    case ProgramGroup of
      DefaultProgGroup: WriteToLogFile( 'Default Program Group' );
      ModFlow: WriteToLogFile( 'Modflow Program Group' );
    end;
  end; {-Procedure SetProgramGroup}

begin
  iError := cUnknownError;
  FullPathNameOfIniFile := ExpandFileName( IniFileName );
  WriteToLogFileFmt( 'Initialising TTrishellDataSet from file: "%s".',
    [FullPathNameOfIniFile] );
  Try
    Inherited Create( AOwner );
    fini := TIniFile.Create( FullPathNameOfIniFile );


 {cDefaultHeader = '-';
 cDefaultProjectID = '-';
 cDefaultDescription = '-';}


    with fini do begin
      WriteToLogFile( 'Reading section [Version]' );
      VersionStr := ReadString( 'Version', 'Version', cDefaultVersion );
      WriteToLogFileFmt( 'Version: "%s".', [VersionStr] );
      WriteToLogFile( 'Reading section [Header]' );
      with Header do begin
        DescriptionStr := ReadString( 'Header', 'Description', cDefaultDescription );
        WriteToLogFileFmt( 'Description: "%s".', [DescriptionStr] );

        Flairs.Transient := false;
        TrishellDataSetType := ReadTrishellDataSetType( FullPathNameOfIniFile, iError );

        Write( 'Trishell Dataset Type: ' );
        case TrishellDataSetType of
          InitialData: WriteToLogFile( 'InitialData' );
          Grid: WriteToLogFile( 'Grid' );
          Calibration: WriteToLogFile( 'Calibration' );
          Scenario: WriteToLogFile( 'Scenario' );
          Final: WriteToLogFile( 'Final' );
          Unsaturated: WriteToLogFile( 'Unsaturated' );
          Transient: WriteToLogFile( 'Transient' );
          PathLine: WriteToLogFile( 'PathLine' );
          Unknown: WriteToLogFile( 'Unknown' );
        end;
        if ( TrishellDataSetType = Transient ) then
          Flairs.Transient := true;

        NameStr        := ReadString( 'Header', 'Name', cDefaultDatasetName );
        WriteToLogFileFmt( 'Name = "%s".', [NameStr] );
        IDStr          := ReadString( 'Header', 'ID', cDefaultDataSetID );
        WriteToLogFileFmt( 'IDStr = "%s".', [IDStr] );
      end; {-with Header}
      WriteToLogFile( 'Reading section [Files]' );
      with Files do begin
        InputFileNameStr  := ReadString( 'Files', 'Input', '' );
        OutputFileNameStr := ReadString( 'Files', 'Output', '' );
        PrintFileNameStr  := ReadString( 'Files', 'Pring', '' );
        LogFileNameStr    := ReadString( 'Files', 'Log', '' );
        TIMfileNameStr    := ReadString( 'Files', 'TIM', '' );
      end; {-with Files}
      WriteToLogFile( 'Reading section [DataSets]' );
      with DataSets do begin
        RelativePathOfGridDataSet := ReadString( 'Datasets', 'Grid', NotAvailableStr );

        {-Triwaco 4.0}
        if ( pos( '.', RelativePathOfGridDataSet ) > 0 ) then
          RelativePathOfGridDataSet := {'..\' +} ExtractWord( 2, RelativePathOfGridDataSet, WordDelimPoint, Len );
        WriteToLogFileFmt( 'Grid: "%s".', [RelativePathOfGridDataSet] );

        RelativePathOfBaseDataSet := ReadString( 'Datasets', 'Base', NotAvailableStr );
        {-Triwaco 4.0}
        if ( pos( '.', RelativePathOfBaseDataSet ) > 0 ) then
          RelativePathOfBaseDataSet := {'..\' +} ExtractWord( 2, RelativePathOfBaseDataSet, WordDelimPoint, Len );
        WriteToLogFileFmt( 'Base: "%s".', [RelativePathOfBaseDataSet] );

        RelativePathOfUnsaturatedDataSet := ReadString( 'Datasets', 'Unsaturated', 'No FLUZO set' );
        {-Triwaco 4.0}
        if ( pos( '.', RelativePathOfUnsaturatedDataSet ) > 0 ) then
          RelativePathOfUnsaturatedDataSet := {'..\' +} ExtractWord( 2, RelativePathOfUnsaturatedDataSet, WordDelimPoint, Len );
        WriteToLogFileFmt( 'Unsaturated: "%s".', [RelativePathOfUnsaturatedDataSet] );
      end;

      SetProgramGroup;

      WriteToLogFile( 'Reading section [Flairs]' );
      with Flairs do begin
        Aquifers := ReadInteger( 'Flairs', 'Aquifers', 0 ); WriteToLogFileFmt( 'Aquifers = %d.', [Aquifers] );
        NrOfSubAreasForWaterBalancCalculations := 0;
        TopSystem := ReadInteger( 'Flairs', 'TopSystem', 0 ); WriteToLogFileFmt( 'TopSystem = %d', [TopSystem] );
        Inner := ReadInteger( 'Flairs', 'Inner', 0 ); WriteToLogFileFmt( 'Inner = %d.', [Inner] );
        Outer := ReadInteger( 'Flairs', 'Outer', 0 ); WriteToLogFileFmt( 'Outer = %d', [Outer] );
        Print := ReadInteger( 'Flairs', 'Print', 0 ); WriteToLogFileFmt( 'Print = %d', [Print] );
        i := ReadInteger( 'Flairs', 'Phreatic', 0 ); Phreatic := ( i > 0 );  {- Phreatic calculations (Iffr)}
        i := ReadInteger( 'Flairs', 'Interface', 0 ); SaltFreshInterface := ( i > 0 ); {- Variable density or salt / fresh water interface (Ifsf)}
        Relax := ReadFloat( 'Flairs', 'Interface', 1.0 );   {- Relaxation factor for non-linear iterations (Rrlax) }
        Converge := ReadFloat( 'Flairs', 'Converge', 0.000001 );
      end;
      Parameters_Section := TOpenSection.CreateFromIniFile( 'Parameters', fini, tmpError, self );
      if ( tmpError <> cNoError ) then
        Raise EErrorCreatingOpenSection.CreateResFmt( @sErrorCreatingOpenSection,
          ['Parameters'] );
      Expressions_Section := TOpenSection.CreateFromIniFile( 'Expressions', fini, tmpError, AOwner );
      if ( tmpError <> cNoError ) then
        Raise EErrorCreatingOpenSection.CreateResFmt( @sErrorCreatingOpenSection,
          ['Expressions'] );
      Result_Section:= TOpenSection.CreateFromIniFile( 'Result', fini, tmpError, AOwner );
      if ( tmpError <> cNoError ) then
        Raise EErrorCreatingOpenSection.CreateResFmt( @sErrorCreatingOpenSection,
          ['Result'] );
      free;
    end; {-with fini}

    WriteToLogFileFmt( 'TTrishellDataSet succesfully initialised from file: "%s".',
      [FullPathNameOfIniFile] );
    iError := cNoError;
  except
    On E: EErrorCreatingOpenSection do begin
      HandleError(  E.Message, false );
      HandleError(  Format( sTrishellDataSetCouldNotBeInitialisedFromFile,
        [FullPathNameOfIniFile] ), true );
    end;
    On E: Exception do begin
      HandleError(  E.Message, false );
      HandleError(  Format( sTrishellDataSetCouldNotBeInitialisedFromFile,
        [FullPathNameOfIniFile] ), true );
    end;
  end;
end; {-Constructor TTrishellDataSet}

Function TTrishellDataSet.FullPathOfGridDataSet: String;
var
  InitDir: String;
begin
  Try
    InitDir := GetCurrentDir;
    if ( DataSets.RelativePathOfGridDataSet <> NotAvailableStr ) then begin
      ChDir( ExtractFileDir( FullPathNameOfIniFile ) );
      if ( GetTrishellDataSetType <> Grid ) then
        ChDir( '..\' + DataSets.RelativePathOfGridDataSet );
      Result := GetCurrentDir;
    end else
      Result := NotAvailableStr;
  finally
    ChDir( InitDir );
  end;
end;

Function TTrishellDataSet.FullPathOfGridFileName: String;     {-grid.teo}
begin
  Result := FullPathOfGridDataSet + '\grid.teo';
end;

Function TTrishellDataSet.FullPathOfOutputFileName: String;  {-flairs.flo}
begin
  Result := ExtractFileDir( FullPathNameOfIniFile ) + '\flairs.flo';
end;

Function TTrishellDataSet.GetID: String;
begin
  Result := Header.IDStr;
end;

Function TTrishellDataSet.GetDescription: String;
begin
  Result := Header.DescriptionStr;
end;

Function TTrishellDataSet.HasBaseDataSet: Boolean;
begin
  Result := ( DataSets.RelativePathOfBaseDataSet <> NotAvailableStr );
end;

Function TTrishellDataSet.BaseDataSet: String;
begin
  if HasBaseDataSet then
    Result := DataSets.RelativePathOfBaseDataSet
  else
    Result := '';
end;

Function TTrishellDataSet.GetTrishellDataSetType: TTrishellDataSetType;
begin
  Result := Header.TrishellDataSetType;
end;

Function TTrishellDataSet.GetNrOfAquifers: Integer;
begin
  case GetTrishellDataSetType of
    InitialData, Calibration, Scenario, Final, Transient, PathLine:
      Result := Flairs.Aquifers
    else
      Result := 0;
  end;
end;

{-TPathLineDataSet ------------------------------------------------------------}

Constructor TPathLineDataSet.CreateFromIniFile( Const IniFileName: String;
  var iError: Integer; AOwner: TComponent );
begin
  iError:= cUnknownError;
  WriteToLogFile( 'Initialising PathLineDataSet.' );
  Try
    Inherited CreateFromIniFile( IniFileName, iError, AOwner );
    if ( iError = cNoError ) then begin
      if ( Header.TrishellDataSetType <> PathLine ) then begin
        iError := cUnknownError;
        Raise EIsNotATraceDataSet.CreateResFmt( @sIsNotATraceDataSet,
          [FullPathNameOfIniFile] );
      end else begin
        WriteToLogFile( 'PathLineDataSet is initialised.' );
      end;
    end else begin
      Raise EErrorReadingTraceDataSet.CreateResFmt( @sErrorReadingTraceDataSet,
        [FullPathNameOfIniFile] );
    end;
  Except
    On E: EIsNotATraceDataSet do begin
      HandleError(  E.Message, true );
      HandleError(  Format( sErrorReadingTraceDataSet, [FullPathNameOfIniFile] ),
        false );
    end;
    On E: EErrorReadingTraceDataSet do begin
      HandleError(  E.Message, true );
    end;
    On E: Exception do begin
      HandleError(  E.Message, false );
      HandleError(  Format( sErrorReadingTraceDataSet, [FullPathNameOfIniFile] ),
        true );
    end;
  end; {-Except}
end;


{-TTransientDataSet ------------------------------------------------------------}

Function TTransientDataSet.GetGrphNodeValue( const GrphNodeTijdstipNr, AquiferNr: LongInt;
      const PeilbuisID: String ): Double;
begin
  Result := cGraphNodeNoData;
  if HasGrphNodeData then
    Result := GrphNodeMatrix^.GetWaarneming( GrphNodeTijdstipNr, AquiferNr,
    PrimitiveGraphNodePeilbuisIDs.Values[PeilbuisID] );
end;

Function TTransientDataSet.GetPreviousOutputTime( const aOutputTime: TDateTime ): TDateTime;
var
  i: LongInt;
begin
  Result := GetStartTime;
  i := 1;
  while ( i <= GetNrOfSpecifiedOutputTimes ) and ( aOutputTime > GetSpecifiedOutputTime( i ) ) do begin
    Result := GetSpecifiedOutputTime( i );
    Inc( i );
  end;
end;

Function TTransientDataSet.FullPathNameOfGraphNodeUngFileName: String;
var
  InitDir, RelDir: String;
begin
  Try
    Try
      InitDir := GetCurrentDir;
      if ( RelativePathOfGraphNodeUngFile <> NotAvailableStr ) then begin
        ChDir( ExtractFileDir( FullPathNameOfIniFile ) );
        RelDir := ExtractFileDir( RelativePathOfGraphNodeUngFile );
        if Length( RelDir ) > 0  then
          ChDir( RelDir );
        Result := GetCurrentDir + '\' + ExtractFileName( RelativePathOfGraphNodeUngFile );
      end else
        Result := NotAvailableStr;
    finally
      ChDir( InitDir );
    end;
  Except
    Result := NotAvailableStr;
  end;
end;

Function TTransientDataSet.GetDateAndTimeStampOfGrphNodeFile: TDateTime;
begin
  Result := Now;
  if HasGrphNodeData then
    Result := GrphNodeMatrix^.GetDateAndTimeStamp;
end;

Function TTransientDataSet.GetNrOfOutputTimesInGrphNodeMatrix: Integer;
begin
  Result := 0;
  if HasGrphNodeData then
    Result := GrphNodeMatrix^.GetAantalTijdstippen;
end;

Function TTransientDataSet.GetNrOfSpecifiedOutputTimes: LongInt;
begin
  Result := TimeSteps_Section.NrOfIdentifiers;
end;

Function TTransientDataSet.IsSpecifiedOutputTime( const aOutputTime: TDateTime ): Boolean;
var
  i: LongInt;
begin
  Result := false;
  i := 1;
  Repeat
    if ( aOutputTime = GetSpecifiedOutputTime( i ) ) then begin
      Result := true
    end else
      Inc( i );
  until Result or ( i = GetNrOfSpecifiedOutputTimes );
end;

Function TTransientDataSet.GetSpecifiedOutputTime( const aOutputTimeIndex: LongInt ): TDateTime;
var
  OriginalDateSeparator: Char;
  ValueOfIdentifier: String;
begin
  Result := GetStartTime;
  if ( aOutputTimeIndex > 0  ) and ( aOutputTimeIndex <= GetNrOfSpecifiedOutputTimes ) then begin
    with FormatSettings do begin {-Delphi XE6}
      OriginalDateSeparator := DateSeparator;
    end;
    Try
      Try
        with FormatSettings do begin {-Delphi XE6}
          DateSeparator := '/';
        end;
        ValueOfIdentifier := TimeSteps_Section.GetValueOfIdentifier( IntToStr( aOutputTimeIndex ) );
        if ( ValueOfIdentifier <> '' ) then
          Result := StrToDateTime ( ValueOfIdentifier );
      Finally
        with FormatSettings do begin {-Delphi XE6}
          DateSeparator := OriginalDateSeparator;
        end;
      end;
    Except
      On E: Exception do begin
        MessageDlg( Format( 'Error: aOutputTimeIndex=%d; ValueOfIdentifier="%s"', [aOutputTimeIndex, ValueOfIdentifier] ), mtError, [mbOk], 0);
      end;
    end;
  end;
end;

Function TTransientDataSet.GetOutputDateTimeOfGrphNodeMatrix( const TijdstipNr: LongInt ): TDateTime;
begin
  if HasGrphNodeData and GrphNodeMatrix^.IsGeldigTijdstipNr( TijdstipNr ) then begin
    Result := GetStartTime + GrphNodeMatrix^.GetTijd( TijdStipNr )
  end else
    Result := GetStartTime;
end;

Function TTransientDataSet.GetStartTime: TDateTime;
begin
  Result := StartTime;
end;

Function TTransientDataSet.GetEndTime: TDateTime;
Begin
  Result := EndTime;
end;

Function TTransientDataSet.GetGrphNodeFileName;
begin
  Result := ExtractFileDir( FullPathNameOfIniFile ) + '\GRAPHNODE.OUT';
end;

Constructor TTransientDataSet.CreateFromIniFile( Const IniFileName: String;
  var iError: Integer; AOwner: TComponent );
var
  f: TextFile;
  Initiated: Boolean;
  fini: TIniFile;
  DefaultDateTime: TDateTime;
  OriginalDateSeparator: Char;
  GraphNodeNamFile, PathNameOfGraphNodeUngFile, S1, S2: String;
  i, j, Len, n: Integer;
Const
  WordDelims = [' '];
begin
  {ShowMessage( 'Initialising TransientDataSet' );}
  iError:= cUnknownError;
  WriteToLogFile( 'Initialising TransientDataSet...' );

  with FormatSettings do begin {-Delphi XE6}
    OriginalDateSeparator := DateSeparator;
  end;
  Try
    {ShowMessage( 'Hierbenik0' );}
    Inherited CreateFromIniFile( IniFileName, iError, AOwner );
    if ( iError = cNoError ) then begin
      if ( Header.TrishellDataSetType <> Transient ) then begin
        iError := cUnknownError;
        Raise EIsNotATransientDataSet.CreateResFmt( @sIsNotATransientDataSet,
          [FullPathNameOfIniFile] );
      end else begin
        fini := TIniFile.Create( IniFileName );
        GraphNodeNamStrings := TStringList.Create;
        PrimitiveGraphNodePeilbuisIDs := TStringList.Create;
        with fini do begin
          {ShowMessage( 'Hierbenik1' );}
          WriteToLogFile( 'Reading Transient elements of section: [Flairs]' );
          DefaultDateTime := StrToDateTime('1/1/1900 12:00');
          with FormatSettings do begin {-Delphi XE6}
            DateSeparator := '/';
          end;
          StartTime := ReadDateTime( 'Flairs', 'StartTime', DefaultDateTime );
          if StartTime = DefaultDateTime then
            StartTime := ReadDateTime( 'Time', 'starttime', DefaultDateTime ); {-Triwaco 4.0}
          EndTime := ReadDateTime( 'Flairs', 'EndTime', DefaultDateTime );
          if EndTime = DefaultDateTime then
            EndTime := ReadDateTime( 'Time', 'endtime', DefaultDateTime ); {-Triwaco 4.0}
          WriteToLogFile( 'StartTime= '+ DateTimeToStr( StartTime ) );
          WriteToLogFile( 'EndTime= ' + DateTimeToStr( EndTime ) );
          {ShowMessage( 'Hierbenik2' );}

          RelativePathOfGraphNodeUngFile := ReadString( 'Flairs', 'GraphNodeUng',  NotAvailableStr );
          {-Triwaco 4.0}
          if ( pos( '.', RelativePathOfGraphNodeUngFile ) > 0 ) then
            RelativePathOfGraphNodeUngFile := '..\' + ExtractWord( 2, RelativePathOfGraphNodeUngFile, WordDelimPoint, Len );
          if RelativePathOfGraphNodeUngFile = '' then begin
            RelativePathOfGraphNodeUngFile :=  '..\' + Datasets.RelativePathOfGridDataSet + '\Peilbuislokaties.ung';
            if not FileExists( FullPathNameOfGraphNodeUngFileName ) then
              RelativePathOfGraphNodeUngFile := NotAvailableStr
            else
              WriteToLogFileFmt( 'File: [%s] Exists.', [RelativePathOfGraphNodeUngFile] );
          end;

          {ShowMessage( RelativePathOfGraphNodeUngFile );}
          WriteToLogFileFmt( 'RelativePathOfGraphNodeUngFile= [%s]', [RelativePathOfGraphNodeUngFile] );

          if ( RelativePathOfGraphNodeUngFile <> NotAvailableStr ) then begin
            PathNameOfGraphNodeUngFile := FullPathNameOfGraphNodeUngFileName;
            WriteToLogFileFmt( 'FullPathNameOfGraphNodeUngFileName= [%s]', [PathNameOfGraphNodeUngFile] );
            if ( PathNameOfGraphNodeUngFile <> NotAvailableStr ) then begin
              GraphNodeNamFile := ChangeFileExt( PathNameOfGraphNodeUngFile, '.nam' );
              WriteToLogFileFmt( 'Load file: [%s]', [GraphNodeNamFile] );
              if FileExists( GraphNodeNamFile ) then begin
                GraphNodeNamStrings.LoadFromFile( GraphNodeNamFile );
                for i:=0 to Pred( GraphNodeNamStrings.count ) do begin
                  S1 := Trim( ExtractWord( 1, GraphNodeNamStrings[ i ], WordDelims, Len ) );
                  S2 := Trim( ExtractWord( 2, GraphNodeNamStrings[ i ], WordDelims, Len ) );
                  Try
                    j := StrToInt( S1 );
                    GraphNodeNamStrings[ i ] := IntToStr(j) + '=' + S2;
                  Except
                    GraphNodeNamStrings[ i ] := 'XXXXXXX';
                  End;
                  WriteToLogFileFmt( 'GraphNodeNamStrings[%d] = "%s".',
                    [i, GraphNodeNamStrings[ i ]] );
                end;
              end;
            end;
          end;
        end;

        TimeSteps_Section := TOpenSection.CreateFromIniFile( 'TimeSteps', fini,
          iError, self );

        if ( iError <> cNoError ) then
          Raise EErrorCreatingOpenSection.CreateResFmt( @sErrorCreatingOpenSection,
            ['TimeSteps'] );

        if FileExists( GetGrphNodeFileName ) then begin
          WriteToLogFileFmt( 'File: [%s] found.', [GetGrphNodeFileName] );
          New( GrphNodeMatrix );
          AssignFile( f, GetGrphNodeFileName ); Reset( f );
          GrphNodeMatrix^ := TGrphNodeMatrix.InitFromOpenedTextFile( f, self, Initiated );
          if ( not Initiated ) then begin
            Try
              GrphNodeMatrix^.free;
              GrphNodeMatrix := nil;
            Except
            end;
          end else begin
            GrphNodeMatrix^.SetDateAndTimeStamp( GetGrphNodeFileName );
            WriteToLogFileFmt( 'DateAndTimeStamp of file [%s] is [%s]',
              [GetGrphNodeFileName, DateTimeToStr( GrphNodeMatrix^.GetDateAndTimeStamp )] );
            n := GrphNodeMatrix^.GetAantalPeilbuizen;
            WriteToLogFileFmt( 'Aantal peilbuizen = %d.', [n] );
            for i:=1 to n do begin
              PrimitiveGraphNodePeilbuisIDs.Append(
                GetPeilbuisID( i ) + '=' + GrphNodeMatrix^.GetPeilbuisID( i ) );
              WriteToLogFileFmt( 'PrimitiveGraphNodePeilbuisIDs[%d] = "%s".',
                [i, PrimitiveGraphNodePeilbuisIDs[ i-1 ]] );
            end;
          end;
          CloseFile( f );
        end else begin
          WriteToLogFileFmt( 'File: [%s] not found: no graphnode output available.', [GetGrphNodeFileName] );
          GrphNodeMatrix := nil;
        end;
        WriteToLogFile( 'TransientDataSet is initialised.' );
      end;
    end else begin
      Raise EErrorReadingTransientDataSet.CreateResFmt( @sErrorReadingTransientDataSet,
        [FullPathNameOfIniFile] );
    end;
  Except
    On E: EIsNotATransientDataSet do begin
      HandleError(  E.Message, true );
      HandleError(  Format( sErrorReadingTransientDataSet, [FullPathNameOfIniFile] ),
        false );
    end;
    On E: EErrorReadingTransientDataSet do begin
      HandleError(  E.Message, true );
    end;
    On E: Exception do begin
      HandleError(  E.Message, false );
      HandleError(  Format( sErrorReadingTransientDataSet, [FullPathNameOfIniFile] ),
        true );
    end;
  end; {-Except}
  with FormatSettings do begin {-Delphi XE6}
    DateSeparator := OriginalDateSeparator;
  end;
end; {-Constructor TTransientDataSet.CreateFromIniFile}

Function TTransientDataSet.HasGrphNodeData: Boolean;
begin
  {Result := false;}

  Result := ( GrphNodeMatrix <> nil ) and
            ( GrphNodeMatrix^.GetAantalPeilbuizen > 0 ) {and
            ( GrphNodeMatrix^.GetAantalTijdstippen > 0 )};
end;

Function TTransientDataSet.ReadGrphNodeData( const OnlyAtSpecifiedOutputTimes: Boolean; AOwner: TComponent ): Boolean;
var
  f: TextFile;
  SelectedTimes: TarrayOfDouble;
  i: Integer;
begin
  Result := false;
  Try
    if not FileExists( GetGrphNodeFileName ) then
      Raise Exception.CreateFmt( 'GraphNodeFile [%s] not found.', [GetGrphNodeFileName] );
    if ( GrphNodeMatrix = nil ) then
      Raise Exception.Create( 'No Graphnode output (GrphNodeMatrix = nil in "ReadGrphNodeData").' );

    if OnlyAtSpecifiedOutputTimes then begin
      SetLength( SelectedTimes, GetNrOfSpecifiedOutputTimes );
      WriteToLogFileFmt( 'TTransientDataSet.ReadGrphNodeData: GetNrOfSpecifiedOutputTimes= %d',
        [GetNrOfSpecifiedOutputTimes] );
      for i:=1 to GetNrOfSpecifiedOutputTimes do begin
        SelectedTimes[ i-1 ] := GetSpecifiedOutputTime( i ) - GetStartTime;
        WriteToLogFileFmt( '%d %g', [i, SelectedTimes[ i-1 ]] );
      end;
    end else begin
      SetLength( SelectedTimes, 0 );
    end;
    AssignFile( f, GetGrphNodeFileName ); Reset( f );
    Try
      Result := GrphNodeMatrix^.ReadGrphNodeData( f, SelectedTimes, AOwner );
    Finally
      CloseFile( f );
      SetLength( SelectedTimes, 0 );
    end;
  Except
    On E: Exception do begin
      HandleError(  E.Message, false );
    end;
  end;
end;

Procedure TTransientDataSet.TrashGrphNodeData;
begin
  if ( GrphNodeMatrix = nil ) then
    Exit;
  Try
    GrphNodeMatrix^.TrashGrphNodeData;
  Except
  end;
end;


Destructor TTransientDataSet.Destroy;
begin
  Try
    if HasGrphNodeData then begin
      GrphNodeMatrix^.free;
      GrphNodeMatrix := nil;
      TimeSteps_Section.Free;
      GraphNodeNamStrings.Free;
      PrimitiveGraphNodePeilbuisIDs.Free;
    end;
    inherited Destroy;
  Except
  End;
end;

Function TTransientDataSet.GetPeilbuisID( const PeilbuisNr: Integer ): String;
begin
  if HasGrphNodeData then begin
    Result := GraphNodeNamStrings.Values[ IntToStr( PeilbuisNr ) ];
    if Result = '' then {-Value not in nam-file}
      Result := GrphNodeMatrix^.GetPeilbuisID( PeilbuisNr )
  end else
    Result := '';
end;

Function TTransientDataSet.GetAantalPeilbuizen: Integer;
begin
  if HasGrphNodeData then
    Result := GrphNodeMatrix^.GetAantalPeilbuizen
  else
    Result := 0;
end;

end.
