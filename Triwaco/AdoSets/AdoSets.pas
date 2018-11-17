Unit AdoSets;
  {-Ado set types.}

Interface

Uses Classes,
     OpWString,
     DUtils,
     LargeArrays{,
     FMX.Grid};

const
  cNODE = 169;
  cSOURCE =170;
  cBOUNDARY = 171;
  cRIVER = 172;
  cGRID = 180;
  cOTHER =181;

Type
  TRealAdoSet = Class( TLargeRealArray )
  private
  public
    SetIdStr: String;
    Procedure   ExportToOpenedTextFile( var f: TextFile );
    Constructor InitFromOpenedTextFile( var f: TextFile; ISetIdStr: String;
                AOwner: TComponent; var LineNr: LongWord;
                var Initiated: Boolean );
    Constructor InitFromOpenedPRNFile( var f, lf: TextFile; ISetIdStr: String;
                AOwner: TComponent; var LineNr: LongWord;
                var Initiated: Boolean );
    Constructor CreateFromCSVFile( FileName: String;
      HasColumnHeaders: Boolean; sep: Char; iColNr: Integer;
        ISetIdStr: String; AOwner: TComponent; var Initiated: Boolean );
    Constructor Create( const NrOfElements: Integer; const ISetId: String; AOwner: TComponent );
                        reintroduce;
    Constructor CreateF( const NrOfElements: Integer; const ISetId: String; const Value: Double;
                         AOwner: TComponent ); reintroduce;
    Function    Getx( i: Integer): Double; Override;
    Procedure   Setx( i: Integer; const Value: Double ); Override;
    Property    Items[Index: Integer]: Double read Getx write Setx; default;
    Function    AdoTime: Double; Virtual;{-Alleen voor set-namen waarin de tijd is verwerkt!}
  end;

  TIntegerAdoSet = Class( TLargeIntegerArray )
  private
  public
    SetIdStr: String;
    Procedure   ExportToOpenedTextFile( var f: TextFile );
    Constructor InitFromOpenedTextFile( var f: TextFile; ISetIdStr: String;
                AOwner: TComponent; var LineNr: LongWord;
                var Initiated: Boolean );
    Constructor Create( NrOfElements: Integer; const ISetId: String; AOwner: TComponent );
                reintroduce;
    Constructor CreateF( NrOfElements: Integer; const ISetId: String; const Value: Integer; AOwner: TComponent );
                reintroduce;
    Function    Getx( i: Integer): Integer; Override;
    Procedure   Setx( i: Integer; const Value: Integer ); Override;
    Property    Items[Index: Integer]: Integer read Getx write Setx; default;
    Function    AdoTime: Double; Virtual;{-Alleen voor set-namen waarin de tijd is verwerkt!}
  end;

  TSetType = ( RealSet, IntegerSet, Unknown );
  TTriwacoParType = ( Node, Source, Boundary, River, Grid, Other );

Function ExtractSetNamesFromTextFile( FileName: String;
                                      SetType: TSetType;
                                      var SetNames: TStringList ): Boolean;
{-Zet setnamen in TStrings. Als er geen setnamen zijn gevonden dan is het
  resultaat nil}

Function FindSet( var f: TextFile; SetIdStr: String;
                  var ResultSetIDStr: String; var LineNr: LongWord ): Boolean;
  {-Find SetIdStr in ado-file. On output, 'LineNr' equals the line number
    where the set was found or the number of lines in the file PLUS ONE.
    If set was not found due to a read error, 'LineNr' equals the line
    number where the read-error occurred. Specify SetIdStr='$' or SetIdStr='*'
    to find any set}

Function MoreThanOneSetsLike_SetIdStr( var f: TextFile;
                                       SetIdStr: String ): Boolean;
  {-Kijkt of er meer dan 1 sets zijn in het geopende bestand f waarvan de naam
    voldoet aan het masker 'SetIdStr'. }

Function MainPartOf_SetIdStr( SetIdStr: String ): String;
  {-Selecteert het eerste deel van de set-string, dus zonder ',STEADY-STATE'
    e.d.}

Procedure SplitFileAndSetStr( FileAndSetStr: String; var FileStr, SetStr: String );
  {-Spit FileAndSetStr on (first) markation character '$'}

Function GetAdoTimeStr( const Time: Double ): String;
  {-Geeft deel ',TIME=   50.00' van ado-set}

Function ExtractTime( const SetIdStr: String ): Double;
  {-Haalt tijdstip uit string ',TIME=   50.00' van ado-set}

Function GetTriwacoParType( const TriwacoParStr: String ): TTriwacoParType;
  {-Leidt het flairs parameter type af uit de TriwacoParStr, bijv. RP1 levert type 'node' op }

Procedure Register;

Implementation
Uses
  SysUtils, Forms, Controls,
  uError;

const
  NumberWidthDelims : CharSet = ['I','E','F','G','.',')'];
  mpConstant                   = 1;
  mpSequential                 = 2;

  cSetNotFound                 = 1;
  cErrReadingModPar            = 2;
  cErrReadingNrOfElements      = 3;
  cInvalidNumberwidthStr       = 4;
  cInvalidNumberType           = 5;
  cErrorFillingColumn          = 6;
  cUnknownModPar               = 7;
  cErrReadingRealConst         = 8;
  cErrReadingIntegerConst      = 9;
var
  Line: string[ 80 ];
  Chars_Node, Chars_Source, Chars_Boundary, Chars_River, Chars_Grid: TStringList;

Function GetTriwacoParType( const TriwacoParStr: String ): TTriwacoParType;
var
  s2: String[2]; s3: String[3];
  l1: integer;
begin
  {Node, Source, Boundary, River, Grid, Other}
  Result := Other;
  l1 := length( TriwacoParStr );
  if ( ( l1 >= 2 ) ) then begin
    s2 := Copy( TriwacoParStr, 1, 2 );
    if ( Chars_Node.IndexOf( s2 ) > -1 ) then begin
      Result := Node; Exit;
    end;
    if ( Chars_Source.IndexOf( s2 ) > -1 ) then begin
      Result := Source; Exit;
    end;
    if ( Chars_Boundary.IndexOf( s2 ) > -1 ) then begin
      Result := Boundary; Exit;
    end;
    if ( Chars_River.IndexOf( s2 ) > -1 ) then begin
      Result := River; Exit;
    end;
    if ( l1 > 2 ) then begin
      s3 := Copy( TriwacoParStr, 1, 3 );
      if ( Chars_Grid.IndexOf( s3 ) > -1 ) then begin
        Result := Grid; Exit;
      end;
    end;
  end;
end;

Function GetAdoTimeStr( const Time: Double ): String;
var
  i: Integer;
begin
  Result := FormatFloat( '00000.00', Time );
  i:=1;
  while ( i <= 4 ) and ( Result[ i ]= '0' ) do begin
    Result[ i ] := ' ';
    Inc( i );
  end;
  Result := ',TIME=' + Result;
end;

Function ExtractTime( const SetIdStr: String ): Double;
var
  SeparatorPos: Integer;
begin
  Result := -1;
  Try
    SeparatorPos := Pos( ':', SetIdStr );
    if ( SeparatorPos = 0 ) then
      SeparatorPos := Pos( '=', SetIdStr );
    Result := StrToFloat( Trim( Copy( SetIdStr, SeparatorPos + 1, 20 ) ) );
  except
  end;
end;

{True als karakters Numberwidth karakters succesvol zijn gelezen}
Function ReadMyString( var f: TextFile; StringWidth: Integer;
                     var ResultStr: String ): Boolean;
var
  i: Integer;
begin
  SetLength( ResultStr, StringWidth );
  for i:=1 to StringWidth do begin
    {$I-} Read( f, ResultStr[ i ] ); {$I+}
  end;
  ReadMyString := ( IOResult = 0 );
end;

Function FindSet( var f: TextFile; SetIdStr: String;
                  var ResultSetIDStr: String; var LineNr: LongWord ): Boolean;
var
  Found: Boolean;
  SId : String[5];
  I: Integer;
  S: String;

Function EqualSetString( S, SetIdStr: String ): Boolean;
  var SSetIdStr: String;
  begin
    S        := AnsiUppercase( Trim( S ) );
    SetIdStr := AnsiUppercase( Trim( SetIdStr ) );
    if ( Pos( '$', SetIdStr ) <> 0 ) then begin
      SSetIdStr := copy( SetIdStr, 1, Length( SetIdStr ) - 1 );
      equalsetstring := ( Pos( SSetIdStr, S ) <> 0 );
    end else
      EqualSetString := ( AnsiCompareText( S, SetIdStr )= 0 )
  end;
begin
  //WriteToLogFileFmt( '  Looking for set "', SetIdStr, '".');
  WriteToLogFileFmt( '  Looking for set "%s".', [SetIdStr] );
  Found := False; FindSet := False;
  while (not EOF(F)) and (not Found) do begin
    {$I-} Readln( f, SId, ResultSetIDStr ); {$I+}
    I := IoResult; if I <> 0 then exit;
    ResultSetIDStr := Trim( ResultSetIDStr );
    Inc( LineNr );
    if ( AnsiCompareText( SId, '*SET*' )= 0 ) then begin
      S := Copy( ResultSetIDStr, 1, Length( SetIdStr ) );
      if ( SetIdStr='$' ) or ( SetIdStr='*' ) or EqualSetString( S, SetIdStr ) then begin
        Found  := True;
        FindSet := Found;
        //WriteToLogFileFmt( '  Set ''',ResultSetIDStr,''' found in line ', LineNr-1, '.' );
        WriteToLogFileFmt( '  Set "%s" found in line %d', [ResultSetIDStr, LineNr-1] );
      end;
    end; {if}
  end; {while}
end;

Function MoreThanOneSetsLike_SetIdStr( var f: TextFile;
                                       SetIdStr: String ): Boolean;
var
  ResultSetIDStr: String;
  LineNr: LongWord;
begin
  Reset( f );
  LineNr := 0;
  Result := FindSet( f, SetIdStr, ResultSetIDStr, LineNr ) and
            FindSet( f, SetIdStr, ResultSetIDStr, LineNr );
  Reset( f );
end;

Function MainPartOf_SetIdStr( SetIdStr: String ): String;
const
  Delims : CharSet = [',','~','_'];
var  
  Len: Integer;
begin
  Result := ExtractWord( 1, SetIdStr, Delims, Len );
end;

Procedure Undo( ErrorCode: Byte; var Initiated: Boolean );
  begin
    case ErrorCode of
      cSetNotFound: HandleError( '  Set not found.', false ); //WriteToLogFileFmt( '  Set not found.' );
      cErrReadingModPar: HandleError( '  Error Reading ModPar.', false ); //WriteToLogFileFmt( '  Error Reading ModPar.' );
      cErrReadingNrOfElements:
        HandleError( '  Error reading NrOfElements.', false ); //WriteToLogFileFmt( '  Error reading NrOfElements.' );
      cInvalidNumberwidthStr: HandleError( '  Invalid numberwidth string.', false ); // WriteToLogFileFmt( '  Invalid numberwidth string.' );
      cInvalidNumberType:
        HandleError( '  Element-type not supported.', false ); //WriteToLogFileFmt( '  Element-type not supported.');
      cErrorFillingColumn: HandleError( '  Error filling column.', false ); //WriteToLogFileFmt( '  Error filling column.' );
      cUnknownModPar: HandleError( '  Unknown ModPar.', false ); //WriteToLogFileFmt( '  Unknown ModPar.' );
      cErrReadingRealConst: HandleError( '  Error reading real-constant.', false ); //WriteToLogFileFmt( '  Error reading real-constant.' );
      cErrReadingIntegerConst: HandleError( '  Error reading integer-constant.', false ); //WriteToLogFileFmt( '  Error reading integer-constant.' );
    else
      HandleError( '  Unknown Errorcode in "InitFromOpenedTextFile".', false );
      //WriteToLogFileFmt( '  Unknown Errorcode in ' + '"InitFromOpenedTextFile".' );
    end;
    Initiated := False;
    // WriteToLogFileFmt( 'Set NOT initialised.' );
    HandleError( 'Set NOT initialised.', false );
  end;

Constructor TRealAdoSet.Create( const NrOfElements: Integer; const ISetId: String;
                                AOwner: TComponent );
begin
  Inherited Create( NrOfElements, AOwner );
  SetIdStr := ISetId;
end;

Function TRealAdoSet.AdoTime: Double;
begin
  Result := ExtractTime( SetIdStr );
end;

Constructor TRealAdoSet.CreateF( const NrOfElements: Integer; const ISetId: String;
                                 const Value: Double; AOwner: TComponent );
begin
  Inherited CreateF( NrOfElements, Value, AOwner );
  SetIdStr := ISetId;
end;

Function TRealAdoSet.Getx( i: Integer): Double;
begin
  if ( NrOfElements > 1 ) then
    Result := Inherited Getx( i )
  else
    Result := Inherited Getx( 1 );
end;

Procedure TRealAdoSet.Setx( i: Integer; const Value: Double );
begin
  if ( NrOfElements > 1 ) then
    Inherited Setx( i, Value )
  else
    Inherited Setx( 1, Value );
end;

Procedure TRealAdoSet.ExportToOpenedTextFile( var f: TextFile );
var
  i: Integer;
  S: String[2];
const
  NrOnLine = 4;
begin
  WriteToLogFileFmt( '  Exporting set "%s" to ado-file.', [SetIDStr] );
  //WriteToLogFileFmt( '  Exporting set "' + SetIDStr + '" to ado-file');
  Writeln( f, '*SET*' + SetIDStr );
  if ( NrOfElements > 1 ) then begin
    Writeln( f, '2' );
    Write( f, NrOfElements:5 );
    Str( NrOnLine, S );
    Writeln( f, '     ('+S+'E19.12)');
    for i:=1 to NrOfElements do begin
      Write( f, GetAdoGetal( Getx( i ) ) );
      if ( ( (i mod NrOnLine ) = 0 ) or ( i = NrOfElements ) ) then
        Writeln( f );
    end;
  end else begin
    Writeln( f, '1' );
    Writeln( f, FloatToStrF( Getx( 1 ), ffGeneral, 15, 2 ) );
  end;
  Writeln( f, 'ENDSET' );
  Writeln( f, line );
  //WriteToLogFileFmt( '  Set exported.' );
  WriteToLogFile( '  Set exported.' );
end; {-Procedure TRealAdoSet.ExportToOpenedTextFile}

Constructor TRealAdoSet.InitFromOpenedTextFile( var f: TextFile;
            ISetIdStr: String; AOwner: TComponent; var LineNr: LongWord;
            var Initiated: Boolean );
var
  INrOfElements, NumberWidth: Integer;
  I, Len, Code: Integer;
  ModPar: Byte;
  FormatString: String[ 20 ];
  NumberWidthStr: String[ 2 ];
  ValueR: Real;
  ResultSetIDStr: String;

Function FillColumn( var f: TextFile; NrOfElements: Integer;
                         NumberWidth: Byte; var LineNr: LongWord ): Boolean;
  {-Fill NrOfElements- real array-elements from ado-file}
var
  NrRead, i: Integer;
  Code: Integer;
  ValueRStr: String;
  Leesfout, StringIsRead: Boolean;
begin
  WriteToLogFile( '  Filling column.' ); //WriteToLogFileFmt('  Filling column.');
  NrRead   := 0;
  Leesfout := False;
  StringIsRead := False;
  while ( ( not Leesfout ) and ( NrRead < NrOfElements ) ) do begin
    while ( ( not Leesfout ) and ( not EOLN( f ) ) and
          ( NrRead < NrOfElements ) ) do begin
      Code := 1; ValueR := -999;
      if Numberwidth > 0 then begin
        StringIsRead := ReadMyString( f, NumberWidth, ValueRStr );
        if ( StringIsRead ) then begin
          Val( ValueRStr, ValueR, Code );
          if ( Code <> 0 ) then begin
            HandleError( Format( '  Error reading element in line: %d.', [LineNr] ), false ); // WriteToLogFileFmt( '  Error reading element in line: ', LineNr, '.');
            HandleError( Format( '  ValueRStr= "%s".', [ValueRStr] ), false ); //WriteToLogFileFmt( '  ValueRStr= "' + ValueRStr + '"' );
          end;
        end else begin
          HandleError( Format( '  Error reading element in line: %d.', [LineNr] ), false ); //WriteToLogFileFmt( '  Error reading element in line: ', LineNr, '.' );
        end;
      end else begin
        HandleError( Format( '  Reals that are %d characters wide cannot be read.', [Numberwidth] ), false ); //WriteToLogFileFmt( '  Reals that are ', Numberwidth, ' characters wide cannot be read.' );
        Code := -1;
      end;
      Leesfout := ( ( not StringIsRead ) or ( Code <> 0 ) );
      // Ga door met lezen als er geen leesfout is opgetreden.
      if ( not Leesfout ) then begin
        Inc( NrRead );
        Setx( NrRead, ValueR ); {WriteToLogFileFmt( ValueR );}
      end; {if}
    end; {while not EOLN(LN)}
    if ( ( not Leesfout ) and ( NrRead < NrOfElements ) ) then begin
      {$I+} Readln( f ); {$I-} Inc( LineNr );
      I := IoResult;
      Leesfout := ( I <> 0 );
    end;
  end; {while}
  FillColumn := ( not Leesfout );
end; {-FillColumn}

begin
  //WriteToLogFileFmt( 'Trying to initialise set "' + ISetIdStr + '".' );
  WriteToLogFileFmt( 'Trying to initialise set "%s".', [ISetIdStr] );
  Initiated := True;
  {-Look for set in file}
  if not FindSet( f, ISetIdStr, ResultSetIDStr, LineNr ) then begin
    Undo( cSetNotFound, Initiated );
  end else begin
    SetIdStr := ResultSetIDStr;
    {-Read mode-parameter}
    WriteToLogFile( '  Reading ModPar.' ); //WriteToLogFileFmt( '  Reading ModPar.');
    {$I-} Readln( f, ModPar ); {$I+} I := IoResult;
    if ( I <> 0 ) then begin
      Undo( cErrReadingModPar, Initiated );
    end else begin
      Inc( LineNr );
      case ModPar of
        mpConstant : begin
          WriteToLogFile( '  Initialising constant real-array.' ); //WriteToLogFileFmt( '  Initialising constant real-array.' );
          INrOfElements := 1;
          try
            Inherited Create( INrOfElements, AOwner );
            Readln( f, ValueR ); Inc( LineNr );
            Setx( 1, ValueR );
          except
            Undo( cErrReadingRealConst, Initiated );
          end;
          WriteToLogFileFmt( 'Set "%s" initialised.', [SetIdStr] ); //WriteToLogFileFmt( 'Set "' + SetIdStr + '" initialised.' );
        end; {mpconstant}
        mpSequential : begin
          WriteToLogFile( '  Initialising sequential array.' ); // WriteToLogFileFmt( '  Initialising sequential array.' );
          WriteToLogFile( '  Reading NrOfElements and FormatString.' ); // WriteToLogFileFmt( '  Reading NrOfElements and FormatString.' );
          {$I-} Readln( f, INrOfElements, FormatString ); {$I+} I := IoResult;
          if ( I <> 0 ) then begin
            Undo( cErrReadingNrOfElements, Initiated );
          end else begin
            Inc(LineNr);
            FormatString   := Trim(Uppercase( FormatString ));
            NumberWidthStr := ExtractWord( 2, FormatString,
                              NumberWidthDelims, Len );
            Val( NumberWidthStr, NumberWidth, Code );
            if ( Code <> 0 ) then begin
              Undo( cInvalidNumberwidthStr, Initiated );
            end else begin
              //WriteToLogFileFmt('  NrOfElements= ',INrOfElements,
              //            '; Format-string= "',FormatString,'".');
              WriteToLogFileFmt( '  NrOfElements=%d; Format-string= "%s".', [INrOfElements,FormatString] );
              WriteToLogFileFmt( 'Numberwidth = %d.', [NumberWidth] ); //WriteToLogFileFmt('  Numberwidth = ', NumberWidth, '.' );
              if not( (pos('F', FormatString) > 0) or
                      (pos('G', FormatString) > 0) or
                      (pos('E', FormatString) > 0) or
                      (pos('I', FormatString) > 0)) then begin
                Undo( cInvalidNumberType, Initiated );
              end else begin
                if (pos('I', FormatString) > 0) then
                  //WriteToLogFileFmt( 'Integer elements (are read as Real elements).' )
                  WriteToLogFile( 'Integer elements (are read as Real elements).' )
                else
                  WriteToLogFile( '  Real elements.' );
                  // WriteToLogFileFmt( '  Real elements.');
                Inherited Create( INrOfElements, AOwner );
                if not FillColumn( f, NrOfElements, NumberWidth, LineNr )
                then begin
                  Undo( cErrorFillingColumn, Initiated );
                end else begin
                  WriteToLogFileFmt( 'Set "%s" initialised.', [SetIdStr] ); //WriteToLogFileFmt( 'Set "' + SetIdStr + '" initialised.' );
                end;
              end; {if not( (pos('F'}
            end; {if ( Code <> 0 )}
          end; {if ( I <> 0 )}
        end; {mpSequential}
      else
        Undo( cUnknownModPar, Initiated );
      end; {case ModPar}
    end; {if ( I <> 0 )}
  end; {if not FindSet}
end; {-Constructor TRealAdoSet.InitFromOpenedTextFile}

Constructor TRealAdoSet.InitFromOpenedPRNFile( var f, lf: TextFile;
            ISetIdStr: String; AOwner: TComponent; var LineNr: LongWord;
            var Initiated: Boolean );
var
  INrOfElements: Integer;
  ModPar: Byte;
  ValueR: Real;
  
Function FillColumn( var f, lf: TextFile; INrOfElements: Integer;
                     var LineNr: LongWord ): Boolean;
  {-Fill NrOfElements- real array-elements from PRN-file}
var
  NrRead: Integer;
  Leesfout: Boolean;
begin
  WriteToLogFile('  Filling column from PRN-file.');
  NrRead   := 0;
  Leesfout := False;
  while ( ( not EOF( f ) ) and ( not Leesfout ) and ( NrRead < INrOfElements ) ) do begin
    Try
      Readln( f, ValueR ); Inc( LineNr );
    Except
      Leesfout := True;
    end;
    if ( not Leesfout ) then begin
      Inc( NrRead );
      Setx( NrRead, ValueR ); {WriteToLogFileFmt( ValueR );}
    end; {if}
  end; {while}
  FillColumn := ( not Leesfout ) and ( INrOfElements = NrRead );
end; {-FillColumn}

begin
  WriteToLogFileFmt( 'Trying to initialise set "%s" from PRN-file.', [ISetIdStr] );
  Initiated := True;
  WriteToLogFile( 'Read NrOfElements in PRN-file.');
  try
    Readln( f, INrOfElements ); Inc( LineNr );
  except
    Undo( cErrReadingNrOfElements, Initiated );
    Exit;
  end;
  WriteToLogFileFmt( 'INrOfElements= ', [INrOfElements] );
  if ( INrOfElements <= 0 ) then begin
    WriteToLogFile( 'No elements found in PRN-file.' );
    Undo( cErrReadingNrOfElements, Initiated );
    Exit;
  end else begin
    SetIdStr := ISetIdStr;
    {-Set mode-parameter}
    if ( INrOfElements = 1 ) then
      ModPar := mpConstant
    else
      ModPar := mpSequential;

    case ModPar of
      mpConstant : begin
        WriteToLogFile( '  Initialising constant real-array.' );
        try
          Inherited Create( INrOfElements, AOwner );
          Readln( f, ValueR ); Inc( LineNr );
          Setx( 1, ValueR );
        except
          Undo( cErrReadingRealConst, Initiated ); Exit;
        end;
        WriteToLogFileFmt( 'Set "%s" initialised.', [SetIdStr] );
      end; {mpconstant}
      mpSequential : begin
        WriteToLogFile( '  Initialising sequential array.' );
        Inherited Create( INrOfElements, AOwner );
        if not FillColumn( f, lf, INrOfElements, LineNr ) then begin
          Undo( cErrorFillingColumn, Initiated ); Exit;
        end else begin
          WriteToLogFileFmt( 'Set "%s" initialised.', [SetIdStr] );
        end;
      end; {mpSequential}
    end; {case ModPar}
  end; {INrOfElements <= 0}

end; {-Constructor TRealAdoSet.InitFromOpenedPRNFile}

Constructor TRealAdoSet.CreateFromCSVFile( FileName: String;
      HasColumnHeaders: Boolean; sep: Char; iColNr: Integer;
        ISetIdStr: String; AOwner: TComponent; var Initiated: Boolean );
begin
  WriteToLogFileFmt( 'Trying to initialise set [%s] from file [%s]',
  [ISetIdStr, FileName] );
  Initiated := False;
  Try
    Try
      Inherited CreateFromCSVFile( FileName, HasColumnHeaders, sep, iColNr,
        AOwner, Initiated );
      SetIdStr := Uppercase( ISetIdStr );
      if not Initiated then
        raise Exception.Create('Error in LargeArray.CreateFromCSVFile');
    Except
      On E: Exception do begin
        WriteToLogFile( 'Error in TRealAdoSet.InitFromCSVFile.' );
      end;
    End;
    Initiated := True;
  WriteToLogFileFmt( 'Set [%s] initiated from file [%s]',
    [ISetIdStr, FileName] );
  Finally
  End;
end;


Constructor TIntegerAdoSet.Create( NrOfElements: Integer; const ISetId: String; AOwner: TComponent );
begin
  Inherited Create( NrOfElements, AOwner );
  SetIdStr := ISetId;
end;

Constructor TIntegerAdoSet.CreateF( NrOfElements: Integer; const ISetId: String; const Value: Integer; AOwner: TComponent );
begin
  Inherited CreateF( NrOfElements, Value, AOwner );
  SetIdStr := ISetId;
end;

Function TIntegerAdoSet.Getx( i: Integer): Integer;
begin
  if ( NrOfElements > 1 ) then
    Result := Inherited Getx( i )
  else
    Result := Inherited Getx( 1 );
end;

Procedure TIntegerAdoSet.Setx( i: Integer; const Value: Integer );
begin
  if ( NrOfElements > 1 ) then
    Inherited Setx( i, Value )
  else
    Inherited Setx( 1, Value );
end;

Procedure TIntegerAdoSet.ExportToOpenedTextFile( var f: TextFile );
var
  i: Integer;
  S: String[2];
const
  NrOnLine = 14;
begin
  //WriteToLogFileFmt( '  Exporting set "' + SetIDStr + '" to ado-file');
  WriteToLogFileFmt( '  Exporting set "%s" to ado-file.', [SetIDStr] );
  Writeln( f, '*SET*' + SetIDStr );
  if ( NrOfElements > 1 ) then begin
    Writeln( f, '2' );
    Write( f, NrOfElements:5 );
    Str( NrOnLine, S );
    Writeln( f, '     ('+S+'I8)');
    for i:=1 to NrOfElements do begin
      Write( f, Getx( i ):8 );
      if ( ( (i mod NrOnLine ) = 0 ) or ( i = NrOfElements ) ) then
        Writeln( f );
    end;
  end else begin
    Writeln( f, '1' );
    Writeln( f, FloatToStrF( Getx( 1 ), ffGeneral, 15, 2 ) );
  end;
  Writeln( f, 'ENDSET' );
  Writeln( f, line );
  //WriteToLogFileFmt( '  Set exported.' );
  WriteToLogFile( '  Set exported.' );
end; {-Procedure TIntegerAdoSet.ExportToOpenedTextFile}

Constructor TIntegerAdoSet.InitFromOpenedTextFile( var f: TextFile;
            ISetIdStr: String; AOwner: TComponent; var LineNr: LongWord;
            var Initiated: Boolean );
var
  INrOfElements, NumberWidth: Integer;
  I, Len, Code, ValueI: Integer;
  ModPar: Byte;
  FormatString: String[ 20 ];
  NumberWidthStr: String[ 2 ];
  ResultSetIDStr: String;

Function FillColumn( var f: TextFile; NrOfElements: Integer;
                         NumberWidth: Byte; var LineNr: LongWord ): Boolean;
  {-Fill NrOfElements- integer array-elements from ado-file}
var
  NrRead, i, Code: Integer;
  ValueIStr: String;
  Leesfout, StringIsRead: Boolean;
begin
  //WriteToLogFileFmt('  Filling column.');
  WriteToLogFile ( '  Filling column.' );
  NrRead   := 0;
  Leesfout := False;
  StringIsRead := False;
  while ( ( not Leesfout ) and ( NrRead < NrOfElements ) ) do begin
    while ( ( not Leesfout ) and ( not EOLN( f ) ) and
          ( NrRead < NrOfElements ) ) do begin
      Code := 1; ValueI := -999;
      if Numberwidth > 0 then begin
        StringIsRead := ReadMyString( f, NumberWidth, ValueIStr );
        if ( StringIsRead ) then begin
          Val( ValueIStr, ValueI, Code );
          if ( Code <> 0 ) then begin
            //WriteToLogFileFmt( '  Error reading element in line: ', LineNr, '.');
            WriteToLogFileFmt( '  Error reading element in line: %d.', [LineNr] );
            //WriteToLogFileFmt( '  ValueIStr= "' + ValueIStr + '"' );
            WriteToLogFileFmt('  ValueIStr= "%s".', [ValueIStr] );
          end;
        end else begin
          WriteToLogFileFmt( '  Error reading element in line: %d.', [LineNr] );
        end;
      end else begin
        WriteToLogFileFmt( '  Integers that are %d characters wide cannot be read.', [Numberwidth] );
        Code := -1;
      end;
      Leesfout := ( ( not StringIsRead ) or ( Code <> 0 ) );
      // Ga door met lezen als er geen leesfout is opgetreden.
      if ( not Leesfout ) then begin
        Inc( NrRead );
        Setx( NrRead, ValueI ); {WriteToLogFileFmt( ValueI );}
      end; {if}
    end; {while not EOLN(LN)}
    if ( ( not Leesfout ) and ( NrRead < NrOfElements ) ) then begin
      {$I+} Readln( f ); {$I-} Inc( LineNr );
      I := IoResult;
      Leesfout := ( I <> 0 );
    end;
  end; {while}
  FillColumn := ( not Leesfout );
end; {-FillColumn}

begin
  //WriteToLogFileFmt( 'Trying to initialise set "' + ISetIdStr + '".' );
  WriteToLogFileFmt( 'Trying to initialise set "%s".', [ISetIdStr] );
  Initiated := True;
  {-Look for set in file}
  if not FindSet( f, ISetIdStr, ResultSetIDStr, LineNr ) then begin
    Undo( cSetNotFound, Initiated );
  end else begin
    SetIdStr := ResultSetIDStr;
    {-Read mode-parameter}
    //WriteToLogFileFmt( '  Reading ModPar.');
    WriteToLogFile( '  Reading ModPar.' );
    {$I-} Readln( f, ModPar ); {$I+} I := IoResult;
    if ( I <> 0 ) then begin
      Undo( cErrReadingModPar, Initiated );
    end else begin
      Inc( LineNr );
      case ModPar of
        mpConstant : begin
          //WriteToLogFileFmt( '  Initialising constant integer-array.' );
          WriteToLogFile( '  Initialising constant integer-array.' );
          INrOfElements := 1;
          try
            Inherited Create( INrOfElements, AOwner );
            Readln( f, ValueI ); Inc( LineNr );
            Setx( 1, ValueI );
          except
            Undo( cErrReadingIntegerConst, Initiated );
          end;
          //WriteToLogFileFmt( 'Set "' + SetIdStr + '" initialised.' );
          WriteToLogFileFmt( 'Set "%s" initialised.', [SetIdStr] );
        end; {mpconstant}
        mpSequential : begin
          //WriteToLogFileFmt( '  Initialising sequential array.' );
          WriteToLogFile( '  Initialising sequential array.' );
          //WriteToLogFileFmt( '  Reading NrOfElements and FormatString.' );
          WriteToLogFile( '  Reading NrOfElements and FormatString.' );
          {$I-} Readln( f, INrOfElements, FormatString ); {$I+} I := IoResult;
          if ( I <> 0 ) then begin
            Undo( cErrReadingNrOfElements, Initiated );
          end else begin
            Inc(LineNr);
            FormatString   := Trim(Uppercase( FormatString ));
            NumberWidthStr := ExtractWord( 2, FormatString,
                              NumberWidthDelims, Len );
            Val( NumberWidthStr, NumberWidth, Code );
            if ( Code <> 0 ) then begin
              Undo( cInvalidNumberwidthStr, Initiated );
            end else begin
              //WriteToLogFileFmt('  NrOfElements=... ',INrOfElements,
              //            '; Format-string= "',FormatString,'".');
              WriteToLogFileFmt( '  NrOfElements=... %d; Format-string= "%s".',
                [INrOfElements, FormatString] );
              //WriteToLogFileFmt('  Numberwidth = ', NumberWidth, '.' );
              WriteToLogFileFmt( '  Numberwidth = %d.', [NumberWidth] );
              if not (pos('I', FormatString) > 0) then begin
                Undo( cInvalidNumberType, Initiated );
              end else begin
                //WriteToLogFileFmt( '  Integer elements.');
                WriteToLogFile( '  Integer elements.');
                Inherited Create( INrOfElements, AOwner );
                if not FillColumn( f, NrOfElements, NumberWidth, LineNr )
                then begin
                  Undo( cErrorFillingColumn, Initiated );
                end else begin
                  WriteToLogFileFmt( 'Set "%s" initialised.', [SetIdStr] );
                end;
              end; {if not( (pos('I'}
            end; {if ( Code <> 0 )}
          end; {if ( I <> 0 )}
        end; {mpSequential}
      else
        Undo( cUnknownModPar, Initiated );
      end; {case ModPar}
    end; {if ( I <> 0 )}
  end; {if not FindSet}
end; {-Constructor TIntegerAdoSet.InitFromOpenedTextFile}

Function TIntegerAdoSet.AdoTime: Double;
begin
  Result := ExtractTime( SetIdStr );
end;

Function ExtractSetNamesFromTextFile( FileName: String;
                                      SetType: TSetType;
                                      var SetNames: TStringList ): Boolean;
var
  f{, lf}: TextFile;
  SetMarker: String[5];
  ASetName, FormatString: String;
  ASetType: TSetType;
  Save_Cursor: TCursor;
  ModPar: byte;
  I: Integer;
begin
  Result := false;
  Save_Cursor := Screen.Cursor;
  Screen.Cursor := crHourglass;    { Show hourglass cursor }
  try
    {AssignFile( lf, 'OpenRealAdoSetDialog.log' ); Rewrite( lf );}
    AssignFile( f, FileName ); Reset( f );
    {WriteToLogFileFmt( 'File: "' + FileName + '" opened.' );}
    While ( not EOF( f ) ) do begin
      Read( f, SetMarker );
      if ( SetMarker = '*SET*' ) then begin
        Readln( f, ASetName );
        ASetName := Trim( ASetName );
        {WriteToLogFileFmt( 'Set: "' + ASetName + '" found.' );}

        {-Read mode-parameter}
        {$I-} Readln( f, ModPar ); {$I+} I := IoResult;
        if ( I <> 0 ) then
          exit;
        case ModPar of
          mpConstant : ASetType := RealSet;
          mpSequential : begin
            Readln( f, FormatString );
            FormatString := Trim( Uppercase( FormatString ) );
            {WriteToLogFileFmt( 'FormatString: "' + FormatString + '".' );}
            if ( (pos('F', FormatString) > 0) or
                 (pos('G', FormatString) > 0) or
                 (pos('E', FormatString) > 0) ) then begin
              ASetType := RealSet;
              {WriteToLogFileFmt( 'RealSet' );}
            end else if ( pos('I', FormatString) > 0 ) then begin
              ASetType := IntegerSet;
              {WriteToLogFileFmt( 'IntegerSet' );}
            end else begin
              ASetType := Unknown;
              {WriteToLogFileFmt( 'UnknownSet' );}
            end;
          end; {mpSequential}
          else
            ASetType := Unknown;
        end; {case}

        {Case SetType of
          RealSet: WriteToLogFileFmt( 'SetType=RealSet' );
          IntegerSet: WriteToLogFileFmt( 'SetType=IntegerSet' );
          Unknown: WriteToLogFileFmt( 'SetType=UnknownSet' );
        end;}
        if   ( SetType = Unknown ) or
           ( ( ASetType = RealSet ) and ( SetType = RealSet ) ) or
           ( ( ASetType = IntegerSet ) and ( SetType = IntegerSet ) )
           then begin
          {WriteToLogFileFmt( 'Add Setname to SetNames.' );}
          SetNames.Add( ASetName );
          Result := true;
          {WriteToLogFileFmt( 'Setname added to SetNames.' );}
        end else;
      end;{if ( SetMarker = '*SET*' )}
      Readln( f );
    end; {while}
  except
    try
      SetNames.Clear;
    except
    end;
  end;
  {if Result then
    WriteToLogFileFmt( 'Result = true' )
  else
    WriteToLogFileFmt( 'Result = false' );
  Close( lf );}
  Screen.Cursor := Save_Cursor;
  Try
    {$I-} CloseFile( f ); {$I+}
  except
  end;
end;

Procedure SplitFileAndSetStr( FileAndSetStr: String; var FileStr,
                                SetStr: String );
const WordDelims : CharSet=['$',' '];
var Len: Integer;
begin
  FileAndSetStr := Trim( FileAndSetStr );
  FileStr := ExtractWord(1, FileAndSetStr, WordDelims, Len );
  SetStr  := ExtractWord(2, FileAndSetStr, WordDelims, Len );
  {-Replace underscores by spaces in SetStr  }
  while Pos('_',SetStr) > 0 do
    SetStr[Pos('_',SetStr)] := ' ';
end;

procedure Register;
begin
  RegisterComponents('Triwaco', [TRealAdoSet]);
  RegisterComponents('Triwaco', [TIntegerAdoSet]);
end;

initialization

  FillChar(Line, SizeOf(Line), '-');
  Chars_Node := TStringList.Create;
  With Chars_Node do begin
    Add( 'TX' ); Add( 'TY' ); Add( 'AL' ); Add( 'CL' ); Add( 'TH' ); Add( 'RL' ); Add( 'PX' ); Add( 'PY' );
    Add( 'DD' ); Add( 'SC' ); Add( 'PE' ); Add( 'PO' ); Add( 'HH' ); Add( 'HT' ); Add( 'HS' ); Add( 'IR' );
    Add( 'RP' );
  end;
  Chars_Source:= TStringList.Create;
  With Chars_Source do begin
    Add( 'IS' ); Add( 'SH' ); Add( '' ); Add( 'SQ' );
  end;
  Chars_Boundary:= TStringList.Create;
  With Chars_Boundary do begin
    Add( 'IB' ); Add( 'BH' ); Add( 'BA' ); Add( 'BB' );
  end;
  Chars_River:= TStringList.Create;
  with Chars_River do begin
    Add( 'RW' ); Add( 'HR' ); Add( 'CD' ); Add( 'CI' ); Add( 'RA' );  Add( 'BR' );  Add( 'RC' );  Add( 'RQ' );
  end;
  Chars_Grid:= TStringList.Create;
  with Chars_Grid do begin
    Add( 'SRC' ); Add( 'BND' ); Add( 'RIV' ); Add( 'POL' ); Add( 'CIR' );
  end;
finalization
  Chars_Node.Free;
  Chars_Source.Free;
  Chars_Boundary.Free;
  Chars_River.Free;;
  Chars_Grid.Free;
end.
