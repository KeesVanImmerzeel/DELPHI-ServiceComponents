unit xyTable;

interface

uses
  Messages, SysUtils, Classes, LargeArrays, Dialogs, DUtils;

type
  TxyTableDescendant = ( cTxyTable, cTxyTableLinInt );
    {-Wordt gebruikt in 'WriteToTextFile' en 'Clone'.}
  TxyTable = class(TComponent)
  private
    { Private declarations }
    Procedure ShiftYValuesUp; Virtual;
      {-Als uitvoer van 'TestDsModel' tevens als invoer moet dienen, initialiseer
        dan de uit/invoer tabel met 'InitialiseFromDoubleMatrix' en roep daarna
        'ShiftYValuesUp' aan.}
  protected
    { Protected declarations }
    DynArrX, DynArrY: TLargeRealArray;
//    procedure DefinePropterties verwijderd: geeft moeilijk op te lossen
//    problemen in de werkomgeving
//    Procedure DefineProperties(Filer: TFiler); override;
  public
    { Public declarations }
    Constructor Create( NrOfElements: Integer; AOwner: TComponent );
                reintroduce;
    Constructor InitialiseFromTextFile( var f: TextFile; AOwner: TComponent );
    Constructor InitialiseFromDoubleMatrix( const Source: TDoubleMatrix;
                const ColX, ColY: Integer; var iError: Integer; AOwner: TComponent );
    Destructor  Destroy; Override;
//    procedure   ReadAllData( Reader: TReader );
//    procedure   WriteAllData( Writer: TWriter );
    Function    SaveToStream( SaveStream: TStream ): Boolean; Virtual;
    Function    LoadFromStream( LoadStream: TStream ): Boolean; Virtual;
    Function NextXindex( const x: Double;
             const Direction: TDirection ): Integer; Virtual;
      {-= "TLargeRealArray.NextIndxA"}
    Function DxTilNextYChange( const x: Double;
             const Direction: TDirection ): Double; Virtual;
      {-= "TLargeRealArray.DstToNextXvalueA"}
    Function EstimateY( const x: Double;
                        const Direction: TDirection ): Double; Virtual;
      {-Estimate Y in ascending ordered table; no interpolation}

      {Testresultaten op tabel:
       1.00    10.00
       2.00    20.00
       4.00    40.00
       7.00    70.00

       Direction = FORWARD; x, EstimY, NextIndex, DxTilNextYChange:
       0.0 10.0  2  2.0
       1.0 10.0  2  1.0
       1.5 10.0  2  0.5
       2.0 20.0  3  2.0
       3.0 20.0  3  1.0
       4.0 40.0  4  3.0
       6.0 40.0  4  1.0
       7.0 70.0  0  3.4E+0038
       8.0 70.0  0  3.4E+0038

       Direction = BACKWARD; x, EstimY, NextIndex, DxTilNextYChange:
       0.0 10.0  0 -3.4E+0038
       1.0 10.0  0 -3.4E+0038
       1.5 10.0  0 -3.4E+0038
       2.0 10.0  0 -3.4E+0038
       3.0 20.0  2 -1.0
       4.0 20.0  2 -2.0
       6.0 40.0  3 -2.0
       7.0 40.0  3 -3.0
       8.0 70.0  4 -1.0}

    Function    NrOfElements: Integer;
    Function    Getx( const i: Integer): Double; Virtual;
    Procedure   Setx( const i: Integer; const Value: Double ); Virtual;
    Function    Gety( const i: Integer ): Double; Virtual;
    Procedure   Sety( const i: Integer; const Value: Double ); Virtual;
    Property    X[ const i: Integer]: Double read GetX write SetX;
    Property    Y[ const i: Integer]: Double read GetY write SetY;
    Procedure   GetXY( const i: Integer; var x, y: Double ); Virtual;
    Procedure   SetXY( const i: Integer; const x, y: Double ); Virtual;

    {Procedure SortXAscending; Virtual;
    Procedure SortYAscending; Virtual;
    Procedure SortXDescending; Virtual;
    Procedure SortYDescending; Virtual;
    Procedure SortAscendingWithXkey; Virtual;
    Procedure SortAscendingWithYkey; Virtual;}
    Function IsAscendingOnX: Boolean; Virtual;
    Procedure WriteToTextFile( var f: TextFile ); Virtual;
    Function DescendantType: TxyTableDescendant; Virtual;
      {-Nodig in 'Clone'}
    Function Clone( AOwner: TComponent ): TxyTable; Virtual;
      {-Returns a new instance of the TDoubleMatrix-class and copies the data into it}
    Function SearchX( const I_x: Double; var I_index: Integer ): Boolean; Virtual;
      {-True als x gevonden. Er geldt dan: x[I_index] is x, anders I_index = 0}
  published
    { Published declarations }
  end;

  TxyTableLinInt = class(TxyTable)
  private
    { Private declarations }
    Procedure ShiftYValuesUp; Override;
    {-Deze procedure doet niks! Zie verder "TxyTable".}
  protected
    { Protected declarations }
  public
    { Public declarations }
    Function NextXindex( const x: Double;
             const Direction: TDirection ): Integer; Override;
    {-= "TLargeRealArray.NextIndx"}
    Function DxTilNextYChange( const x: Double;
             const Direction: TDirection ): Double; Override;
      {-= "TLargeRealArray.DstToNextXvalue"}
    Function EstimateY( const x: Double;
             const Direction: TDirection ): Double; Override;
      {-Estimate Y in ascending ordered table; linear interpolation}

      {Testresultaten op tabel:
       1.00    10.00
       2.00    20.00
       4.00    40.00
       7.00    70.00

       Direction = FORWARD; x, EstimY, NextIndex, DxTilNextYChange:
       0.0 10.0  1  1.0
       1.0 10.0  2  1.0
       1.5 15.0  2  0.5
       2.0 20.0  3  2.0
       3.0 30.0  3  1.0
       4.0 40.0  4  3.0
       6.0 60.0  4  1.0
       7.0 70.0  0  3.4E+0038
       8.0 70.0  0  3.4E+0038

       Direction = BACKWARD; x, EstimY, NextIndex, DxTilNextYChange:
       0.0 10.0  0 -3.4E+0038
       1.0 10.0  0 -3.4E+0038
       1.5 15.0  1 -0.5
       2.0 20.0  1 -1.0
       3.0 30.0  2 -1.0
       4.0 40.0  2 -2.0
       6.0 60.0  3 -2.0
       7.0 70.0  3 -3.0
       8.0 70.0  4 -1.0}
    Function DescendantType: TxyTableDescendant; Override;
      {-Nodig in 'Clone'}
    Function Clone( AOwner: TComponent ): TxyTableLinInt; Reintroduce; Virtual;
      {-Returns a new instance of the TDoubleMatrix-class and copies the data into it}
  published
    { Published declarations }
  end;

Procedure SortAscendingWithXkey( n: integer; var arr: TxyTable );

procedure Register;

implementation

uses
  uError, Math;

Procedure SortAscendingWithXkey( n: integer; var arr: TxyTable );
begin
end;

Constructor TxyTable.Create( NrOfElements: Integer; AOwner: TComponent );
begin
  Inherited Create( AOwner );
  Try
    DynArrX := TLargeRealArray.Create( NrOfElements, Self );
    DynArrY := TLargeRealArray.Create( NrOfElements, Self );
  Except
    raise Exception.CreateFmt( 'Initialisation failed in: ' +
      '"TxyTable.Create". NrOfElements= %d.', [ NrOfElements ] )
  end;
end;

Function TxyTable.SearchX( const I_x: Double; var I_index: Integer ): Boolean;
begin
  Result := DynArrX.Search( I_x, I_index );
end;

Constructor TxyTable.InitialiseFromTextFile( var f: TextFile;
            AOwner: TComponent );
const
  ColX = 1;
var
  NrOfElements, i, ColY, IErr: Integer;
  x, y: Double;
  TestDsModelOutputFileName: String;
  g: TextFile;
  DM: TDoubleMatrix;
begin
  WriteToLogFile( 'Initialise TxyTable (or descendant) from text-file.' );
  Try
    Inherited Create( AOwner );
    Readln( f, NrOfElements );
    if ( NrOfElements > 0 ) then begin
      WriteToLogFileFmt( 'NrOfElements= %d', [NrOfElements] );
      DynArrX := TLargeRealArray.Create( NrOfElements, Self );
      DynArrY := TLargeRealArray.Create( NrOfElements, Self );
      for i:=1 to NrOfElements do begin
        Readln( f, x, y );
        DynArrX[ i ] := x; DynArrY[ i ] := y;
        {Writeln( lf, 'i,x,y: ', i:6, DynArrX[ i ]:8:2, ' ', DynArrY[ i ]:8:2 );}
      end;
      WriteToLogFile( 'All values read.' );
    end else if ( NrOfElements < 0 ) then begin
      WriteToLogFile( 'Initialise from output-file of "TestDsModel".' );
      ColY := -NrOfElements;
      Readln( f, TestDsModelOutputFileName );
      WriteToLogFileFmt( 'Output-file of "TestDsModel": %s.', [TestDsModelOutputFileName] );
      if not FileExists( TestDsModelOutputFileName ) then begin
        WriteToLogFile( 'File does not exist' );
        raise Exception.Create( 'Initialisation failed in ' +
                            '"TxyTable.InitialiseFromTextFile": specified file does not exist.' );
        Exit;
      end;
      AssignFile( g, TestDsModelOutputFileName ); Reset( g );
      Readln( g, IErr );
      if ( IErr <> cNoError ) then begin
        WriteToLogFileFmt( 'Output in this file starts with error: (%d).', [IErr] );
        WriteToLogFile( 'Therefore this output cannot be used as input.' );
        raise Exception.Create( 'Initialisation failed in ' +
                            '"TxyTable.InitialiseFromTextFile": error in output file to be used as input.' );
        CloseFile( g );
        Exit;
      end;
      Readln( g ); {-Is altijd cTxyTable (=0)}
      DM := TDoubleMatrix.InitialiseFromTextFile( g, NIL );
      CloseFile( g );
      InitialiseFromDoubleMatrix( DM, ColX, ColY, IErr, NIL );
      if ( IErr <> cNoError ) then begin
        WriteToLogFile( 'Error initialising xyTable from DoubleMatrix.' );
        DM.Free;
        raise Exception.Create( 'Initialisation failed in ' +
                            '"TxyTable.InitialiseFromTextFile"; 1ste x-waarde <> 0' );
        Exit;
      end;
      {-x-waarde van eerste (x,y)-element moet 0 zijn}
      if ( DM.GetValue( 1, 1 ) <> 0 ) or ( IErr <> cNoError ) then begin
        WriteToLogFile( 'Fout: x-waarde van eerste (x,y)-element moet 0 zijn!' );
        DM.Free;
        raise Exception.Create( 'Initialisation failed in ' +
                            '"TxyTable.InitialiseFromTextFile"; 1ste x-waarde <> 0' );
        Exit;
      end;
      ShiftYValuesUp;
      DM.Free;
    end else begin
      WriteToLogFile( 'NrOfElements = 0.' );
      raise Exception.Create( 'Initialisation failed in ' +
                            '"TxyTable.InitialiseFromTextFile": NrOfElements=0.' )
    end;
  Except
    raise Exception.Create( 'Initialisation failed in: ' +
                            '"TxyTable.InitialiseFromTextFile".' )
  end;
end;

Constructor TxyTable.InitialiseFromDoubleMatrix( const Source: TDoubleMatrix;
            const ColX, ColY: Integer; var iError: Integer; AOwner: TComponent );
var
  n, m, i: Integer;
begin
  iError := cNoError;
  m := Source.GetNCols;
  if ( ColX < 1 ) or ( ColX > m ) or
     ( ColY < 1 ) or ( ColY > m )then begin
    raise Exception.CreateFmt( 'Invalid ColNr (%d) and/or (%d) in: ' +
      '"TxyTable.InitialiseFromDoubleMatrix".', [ ColX, ColY ]  );
    iError := cUnknownError;
    Exit;
  end;
  n := Source.GetNRows;
  Try
    Create( n, AOwner );
  Except
    raise Exception.CreateFmt( 'Initialisation failed in: ' +
      '"TxyTable.InitialiseFromDoubleMatrix". NrOfElements= %d.', [ n ] );
    iError := cUnknownError;
    Exit;
  end;
  for i:=1 to n do
    Setxy( i, Source.GetValue( i, ColX ), Source.GetValue( i, ColY ) );
end;

Procedure TxyTable.ShiftYValuesUp;
var
  i, n: Integer;
begin
  n := NrOfElements;
  for i:=1 to n-1 do
    Sety( i, Gety( i+1 ) );
end;

Destructor  TxyTable.Destroy;
begin
  DynArrX.Free;
  DynArrY.Free;
  Inherited;
end;

Function TxyTable.IsAscendingOnX: Boolean;
begin
  Result := DynArrX.IsAscending;
end;

Function TxyTable.NrOfElements: Integer;
begin
  Result := DynArrX.NrOfElements;
end;

Function TxyTable.Getx( const i: Integer): Double;
begin
  Result := DynArrX.Getx( i );
end;

Procedure TxyTable.Setx( const i: Integer; const Value: Double );
begin
  DynArrX.Setx( i, Value );
end;

Function TxyTable.Gety( const i: Integer): Double;
begin
  Result := DynArrY.Getx( i );
end;

Procedure TxyTable.Sety( const i: Integer; const Value: Double );
begin
  DynArrY.Setx( i, Value );
end;

Procedure TxyTable.Getxy( const i: Integer; var x, y: Double );
begin
  x := Getx( i ); y := Gety( i );
end;

Procedure TxyTable.Setxy( const i: Integer; const x, y: Double );
begin
  Setx( i, x ); Sety( i, y );
end;

Function TxyTable.EstimateY( const x: Double;
         const Direction: TDirection ): Double;
var
  i, n: Integer;
begin
  n := NrOfElements;
  case n of
    0: Result := 0;
    1: Result := GetY( 1 );
  else
    i := NextXindex( x, Direction );
    if ( Direction = FrWrd ) then begin
      Dec( i );
      if ( i = -1 ) then
        i := NrOfElements;
    end else {-Direction = BckWrd}
      i := Max( i, 1 );
    Result := GetY( i );
  end; { case}
end;

Function TxyTable.NextXindex( const x: Double;
                              const Direction: TDirection ): Integer;
begin
  Result := DynArrX.NextIndxA( x, Direction );
end;

Function TxyTable.DxTilNextYChange( const x: Double;
         const Direction: TDirection ): Double;
begin
  Result := DynArrX.DstToNextXvalueA( x, Direction );
end;

Function TxyTable.DescendantType: TxyTableDescendant;
begin
  Result := cTxyTable;
end;

Procedure TxyTable.WriteToTextFile( var f: TextFile );
var
  i, n: Integer;
  x, y: Double;
begin
  n := NrOfElements;
  {Writeln( f, Ord( DescendantType ) );}
  Writeln( f, n );
  for i:=1 to n do begin
    Getxy( i, x, y );
    Writeln( f, FloatToStrF( x, ffExponent, 8, 2 ), ' ',
                FloatToStrF( y, ffExponent, 8, 2 ) );
  end;
end;

//Procedure TxyTable.DefineProperties(Filer: TFiler);
//begin
//  inherited DefineProperties(Filer);
  { Define new properties and reader/writer methods }
//  Filer.DefineProperty('TxyTableData', ReadAllData, WriteAllData, True );
//end;

//procedure TxyTable.WriteAllData( Writer: TWriter );
//begin
//  DynArrX.WriteAllData( Writer );
//  DynArrY.WriteAllData( Writer );
//end;

//procedure TxyTable.ReadAllData( Reader: TReader );
//begin
//  DynArrX.ReadAllData( Reader );
//  DynArrY.ReadAllData( Reader );
//end;

Function TxyTable.SaveToStream( SaveStream: TStream ): Boolean;
begin
  Try
    Result := DynArrX.SaveToStream( SaveStream ) and
              DynArrY.SaveToStream( SaveStream );
  except
    Result := false;
  End;
end;

Function TxyTable.LoadFromStream( LoadStream: TStream ): Boolean;
begin
  Try
    Result := DynArrX.LoadFromStream( LoadStream ) and
              DynArrY.LoadFromStream( LoadStream );
  Except
    Result := false;
  End;
end;

Function TxyTable.Clone( AOwner: TComponent ): TxyTable;
var
  n: Integer;
begin
  n      := NrOfElements;
  Result := TxyTable.Create( n, AOwner );
  Result.DynArrX.GetDynArr^ := Copy( DynArrX.GetDynArr^, 0, Length( DynArrX.GetDynArr^ ) );
  Result.DynArrY.GetDynArr^ := Copy( DynArrY.GetDynArr^, 0, Length( DynArrY.GetDynArr^ ) );
  Result.DynArrX.Setjlo( DynArrX.Getjlo );
  Result.DynArrY.Setjlo( DynArrY.Getjlo );
end;

Function TxyTableLinInt.NextXindex( const x: Double;
         const Direction: TDirection ): Integer;
begin
  Result := DynArrX.NextIndx( x, Direction );
end;

Function TxyTableLinInt.DxTilNextYChange( const x: Double;
             const Direction: TDirection ): Double;
begin
  Result := DynArrX.DstToNextXvalue( x, Direction );
end;

Function TxyTableLinInt.EstimateY( const x: Double;
         const Direction: TDirection ): Double;
var
  jlo, n: Integer;
  x1, x2, y1, y2, dx, dy: Double;
begin
  n   := NrOfElements;
  if ( n <= 1 ) then
    Result := Inherited EstimateY( x, Direction )
  else begin
    jlo := DynArrX.Hnt( x );

    if ( jlo > 0 ) then begin
      if ( jlo < n ) then begin
        Getxy( jlo, x1, y1 );
        Getxy( jlo+1, x2, y2 );
        dx := x2 - x1;
        dy := y2 - y1;
        if ( abs( dx ) < MinSingle ) then begin
          raise Exception.CreateFmt(
          'Cannot interpolate in table with double x-values: ' + ' %f.', [ x1 ] );
          exit;
        end else begin
          Result := y1 + ( ( x - x1 ) * dy / dx );
        end;
      end else
        Result := Gety( n );
    end else { jlo = 0 }
      Result := Gety( 1 );
  end;
end;

Function TxyTableLinInt.Clone( AOwner: TComponent ): TxyTableLinInt;
var
  n: Integer;
begin
  n      := NrOfElements;
  Result := TxyTableLinInt.Create( n, AOwner );
  Result.DynArrX.GetDynArr^ := Copy( DynArrX.GetDynArr^, 0, Length( DynArrX.GetDynArr^ ) );
  Result.DynArrY.GetDynArr^ := Copy( DynArrY.GetDynArr^, 0, Length( DynArrY.GetDynArr^ ) );
  Result.DynArrX.Setjlo( DynArrX.Getjlo );
  Result.DynArrY.Setjlo( DynArrY.Getjlo );
end;

Function TxyTableLinInt.DescendantType: TxyTableDescendant;
begin
  Result := cTxyTableLinInt;
end;

Procedure TxyTableLinInt.ShiftYValuesUp;
begin
end;

procedure Register;
begin
  RegisterComponents('MyComponents', [TxyTable, TxyTableLinInt]);
end;

begin
  with FormatSettings do begin {-Delphi XE6}
    DecimalSeparator := '.';
  end;
end.
