unit TriwacoPRJ;

interface

uses
  Classes, ComCtrls,
  uTTrishellDataSet;

type
  TTriwacoPRJ = class(TComponent)
  private
    { Private declarations }
    FileName,
    Version,
    Header,
    ProjectID,
    Description: String;
    TrishellDataSet: Array of TTrishellDataSet;

  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor CreateFromIniFile( Const IniFileName: String; var iError: Integer;
      AOwner: TComponent );
    Function GetFileName: String;
    Function PRJdir: String;
    Function GetVersion: String;
    Function GetHeader: String;
    Function GetProjectId: String;
    Function GetDescription: String;
    Function GetAantalTrishellDataSets: Integer;
    Function GetTrishellDataSet( const ID: String ): PTrishellDataSet;
    Procedure AddNodesToTreeView( var aTreeView: TTreeView ); Virtual;
    Function CountNrOfTrishellDataSetOfThisType( const aTrishellDataSetType:
      TTrishellDataSetType ): Integer;
    Function CountNrOfTrishellDataSetsWithGraphnodeData: Integer;
    Function HasGrphNodeData: Boolean;
    Destructor Destroy; Override;
  published
    { Published declarations }
  end;
ResourceString
  sCouldNotCreateTTriwacoPRJFromFile =
    'Could not create Triwaco project from file: "%s".';
const
 cDefaultVersion = '-';
 cDefaultHeader = '-';
 cDefaultProjectID = '-';
 cDefaultDescription = '-';
 cNoDataSet = 'GeenTriwacoDataSet';

procedure Register;

implementation

uses
  SysUtils, iniFiles,
  uError;

{-Procedures, functions -------------------------------------------------------}

procedure Register;
begin
  RegisterComponents('Triwaco', [TTriwacoPRJ]);
end;

{-TTriwacoPRJ -----------------------------------------------------------------}

Function TTriwacoPRJ.PRJdir: String;
begin
  Result := ExtractFileDir( GetFileName );
end;

constructor TTriwacoPRJ.CreateFromIniFile( Const IniFileName: String;
  var iError: Integer; AOwner: TComponent );
var
  iniFile: TiniFile;
  AantalTrishellDataSets, i: Integer;
  aTrishellDataSetID, DataSetIniFileName: String;
  TrishellDataSetType: TTrishellDataSetType;
begin
  Try
    FileName := ExpandFileName( IniFileName );

    WriteToLogFileFmt( 'Initialising TTriwacoPRJ from file [%s].', [FileName] );
    iniFile := TiniFile.Create( FileName );
    with iniFile do begin
      Version := ReadString( 'Version', 'Version', cDefaultVersion );
      Header := ReadString( 'Header', 'Header', cDefaultHeader );
      ProjectID := ReadString( 'ProjectID', 'ProjectID', cDefaultProjectID );
      if ProjectID =cDefaultProjectID then  {-Triwaco 4.0}
        ProjectID := ReadString( 'Header', 'ID', cDefaultProjectID );
      Description := ReadString( 'Description', 'Description', cDefaultDescription );
    end;
    WriteToLogFileFmt( 'Version = "%s".', [Version] );
    WriteToLogFileFmt( 'Header = "%s".', [GetHeader] );
    WriteToLogFileFmt( 'ProjectID = "%s".', [GetProjectID] );
    WriteToLogFileFmt( 'Description = "%s".', [GetDescription] );

    {-Bepaal het aantal TrishellDataSets}
    AantalTrishellDataSets := 0;
    Repeat
      aTrishellDataSetID := iniFile.ReadString( 'DataSets', 'Set' +
        IntToStr( AantalTrishellDataSets + 1 ), cNoDataSet );
      if ( aTrishellDataSetID <> cNoDataSet ) then begin
        DataSetIniFileName := PRJDir + '\' + aTrishellDataSetID + '\Model.ini';
        if DirectoryExists( PRJDir + '\' + aTrishellDataSetID ) and
          FileExists( DataSetIniFileName ) then begin
          Inc( AantalTrishellDataSets );
        end else
          aTrishellDataSetID := cNoDataSet;
      end;
    Until ( aTrishellDataSetID = cNoDataSet );
    WriteToLogFileFmt( 'Aantal TrishellDataSets: %d.', [AantalTrishellDataSets] );

    if ( AantalTrishellDataSets = 0 ) then
      Raise Exception.Create( 'No dataset availabel.' );

    SetLength( TrishellDataSet, AantalTrishellDataSets );
    for i:=0 to AantalTrishellDataSets-1 do begin
      aTrishellDataSetID := iniFile.ReadString( 'DataSets', 'Set' +
        IntToStr( i + 1 ), cNoDataSet );
      DataSetIniFileName := PRJDir + '\' + aTrishellDataSetID + '\Model.ini';

      WriteToLogFileFmt( 'Determine type of Triwaco dataset %d.', [i+1] );
      TrishellDataSetType := ReadTrishellDataSetType( DataSetIniFileName, iError );
      if ( iError <> cNoError ) then begin
        Raise Exception.Create( 'Error reading type of Triwaco dataset.' );
      end;

      Case TrishellDataSetType of
        InitialData, Grid, Calibration, Scenario, Final, Unsaturated:
          begin
            TrishellDataSet[ i ] := TTrishellDataSet.CreateFromIniFile( DataSetIniFileName,
              iError, self );
          end;
        PathLine:
          begin
            TrishellDataSet[ i ] := TPathLineDataSet.CreateFromIniFile( DataSetIniFileName,
              iError, self );
          end;
        Transient:
          begin
            TrishellDataSet[ i ] := TTransientDataSet.CreateFromIniFile( DataSetIniFileName,
              iError, self );
          end;
      end; {-case}
      if ( iError <> cNoError ) then begin
        Raise Exception.Create( 'Error reading Triwaco dataset.' );
      end;
    end;
    iniFile.Free;

    WriteToLogFileFmt( 'TTriwacoPRJ initialised from file: "%s". ', [FileName] );
  except
    On E: Exception do begin
      HandleError(  E.Message, false );
      HandleError(  Format( sCouldNotCreateTTriwacoPRJFromFile,
        [ExpandFileName( IniFileName )] ), true );
    end;
  end;
end; {-constructor TTriwacoPRJ}

Function TTriwacoPRJ.GetAantalTrishellDataSets: Integer;
begin
  Result := Length( TrishellDataSet );
end;

Function TTriwacoPRJ.GetTrishellDataSet( const ID: String ): PTrishellDataSet;
var
  i: Integer;
begin
  Result := nil;
  for i:=0 to GetAantalTrishellDataSets-1 do begin
    if ( TrishellDataSet[ i ].GetID = ID ) then
      Result := @TrishellDataSet[ i ];
  end;
end;

Function TTriwacoPRJ.HasGrphNodeData: Boolean;
begin
  Result := ( CountNrOfTrishellDataSetsWithGraphnodeData > 0 );
end;

Destructor TTriwacoPRJ.Destroy;
var
  i: Integer;
begin
  Try
    for i:=0 to GetAantalTrishellDataSets-1 do
      TrishellDataSet[ i ].Free;
  Except
  end;
  Inherited Destroy;
end;

Function TTriwacoPRJ.GetFileName: String;
begin
  Result := FileName;
end;

Function TTriwacoPRJ.GetVersion: String;
begin
  Result := Version;
end;
Function TTriwacoPRJ.GetHeader: String;
begin
  Result := Header;
end;
Function TTriwacoPRJ.GetProjectID: String;
begin
  Result := ProjectID;
end;

Function TTriwacoPRJ.GetDescription: String;
begin
Result := Description;
end;

Function TTriwacoPRJ.CountNrOfTrishellDataSetOfThisType( const aTrishellDataSetType:
      TTrishellDataSetType ): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i:=0 to GetAantalTrishellDataSets-1 do begin
    if ( TrishellDataSet[ i ].GetTrishellDataSetType = aTrishellDataSetType ) then
      Inc( Result );
  end;
end;

Function TTriwacoPRJ.CountNrOfTrishellDataSetsWithGraphnodeData: Integer;
var
  i: Integer;
  aTransientDataSet: PTransientDataSet;
begin
  Result := CountNrOfTrishellDataSetOfThisType( Transient );
  if ( Result > 0 ) then begin
    for i:=0 to GetAantalTrishellDataSets-1 do begin
      if ( TrishellDataSet[ i ].GetTrishellDataSetType = Transient ) then begin
       aTransientDataSet := PTransientDataSet( TrishellDataSet[ i ] );
       if ( aTransientDataSet^.HasGrphNodeData ) then
         Inc( Result );
      end;
    end;
  end;
end;

Procedure TTriwacoPRJ.AddNodesToTreeView( var aTreeView: TTreeView );
var
  RootNode, aTreeNode: TTreeNode;
  i, j: Integer;
  Found: Boolean;
begin
  WriteToLogFile( 'AddNodesToTreeView' );
  with aTreeView.Items do begin
    Clear; { remove any existing nodes }
    RootNode := Add( nil, '[' + ExtractFileName( GetFileName ) + ']' ); { Add a root node }
    for i:=0 to GetAantalTrishellDataSets-1 do begin
      with TrishellDataSet[ i ] do begin
        WriteToLogFileFmt( 'Dataset: %s.', [TrishellDataSet[ i ].GetID] );
        if HasBaseDataSet then begin
          WriteToLogFileFmt( 'HasBaseDataSet: [%s].', [BaseDataSet] );
          j := 1; Found := false;
          Repeat
            WriteToLogFileFmt( '  testing with [%s].', [aTreeView.Items[ j ].Text] );
            if ( aTreeView.Items[ j ].Text = BaseDataSet ) then begin
              Found := true;
            end else begin
              Inc( j );
            end;
          until Found or ( j = aTreeView.Items.Count-1 );
          if Found then WriteToLogFile( 'found' ) else WriteToLogFile( 'not found' );
          aTreeNode := aTreeView.Items[ j ];
          AddChild( aTreeNode, GetID );
        end else begin
          WriteToLogFile( 'Does not have BaseDataSet' );
          AddChild( RootNode, GetID );
        end;
      end; {-with}
    end; {-for}
    RootNode.Expand( False );
  end; {-with aTreeView.Items}
end;

end.
