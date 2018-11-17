Unit LargeArrays;
  {-Basic large-array types}

{.$RANGECHECKS ON}
{.$Define Test}

Interface

Uses {$ifdef Test}Forms, Windows, {$endif}Classes, SysUtils, System.Math,
 {dialogs,} OpWString, DUtils, Vcl.Grids;

Type
  TarrayOfDouble = array of Double;
  ParrayOfDouble = ^TarrayOfDouble;
  PLargeRealArray = ^TLargeRealArray;
  TLargeRealArray = Class( TComponent )
  private
  protected
    DynArr: TarrayOfDouble;
    jlo: Integer;
    NoDataIsSet: Boolean;
    NoDataValue: Double;
//    procedure DefinePropterties verwijderd: geeft moeilijk op te lossen
//    problemen in de werkomgeving
//    procedure DefineProperties(Filer: TFiler); override;
  public
    Constructor Create( const NrOfElements: Integer; AOwner: TComponent );
                        reintroduce;
    Constructor CreateF( const NrOfElements: Integer; const Value: Double;
                         AOwner: TComponent ); Virtual;
    Constructor CreateByCopy( var aLargeRealArray: TLargeRealArray; const MinIndex, MaxIndex: Integer;
      StripNoDataValues: boolean; AOwner: TComponent ); Virtual;
    Constructor CreateFromCSVFile( FileName: String;
      HasColumnHeaders: Boolean; sep: Char; iColNr: Integer;
        AOwner: TComponent; var Initiated: Boolean );
    Destructor  Destroy; override;
//    procedure   ReadAllData( Reader: TReader );
//    procedure   WriteAllData( Writer: TWriter );
    Constructor CreateFromOpenedTextFile( var f: TextFile; var LineNr: Integer;
      var Initiated: Boolean; AOwner: TComponent ); Virtual;
    Function    SaveToStream( SaveStream: TStream ): Boolean; Virtual;
    Function    LoadFromStream( LoadStream: TStream ): Boolean; Virtual;
    Procedure   WriteToTextFile( var f: TextFile ); Virtual;  {-Write to opened textfile}
    Function    Getx( i: Integer): Double; Virtual;
    Function    NrOfElements: Integer;
    Function    GetSum( var NrOfValuesEvaluated: Integer; var ResultSum: Double ): Boolean; virtual;
    Procedure   Setx( i: Integer; const Value: Double ); Virtual;
    Procedure   SetNoDataValue( const iNoDataValue: Double ); Virtual;
    Function    NoData( const i: Integer ): Boolean; Virtual;
    Function    HasData( const i: Integer ): Boolean; Virtual;
    Function    NrOfDataValues: Integer; Overload;
    Function    NrOfDataValues( const MinIndex, MaxIndex: Integer ): Integer; Overload;
    Function    Full: Boolean; Virtual;
    Function    GetStatInfo( var NrOfValuesEvaluated: Integer; var StatInfo: TStatInfoType ): Boolean ; Virtual;
    Function    Hnt( x: Double ): Integer; Virtual;
    {-Zoekt (met de functie 'Hunt') de index jlo waarvoor geldt:

    Oplopende arrays:
      - Getx( jlo ) < x <= Getx( jlo+1 );
      - als x <= Getx( 1 ), dan jlo = 0;
      - als x >  Getx( NrOfElements ), dan jlo = NrOfElements.

    Voorbeeld: de oplopende reeks 1, 2, 4 en 7 levert de volgende test-
    resultaatwaarden op: (0, 0); (1, 0); (1.5, 1); (2, 1); (3, 2); (4, 2);
    (6, 3); (7, 3); (8, 4)

    Aflopende arrays:
      - Getx( jlo+1 ) < x <= Getx( jlo )
      - als x <  Getx( NrOfElements ), dan jlo = NrOfElements;
      - als x >= Getx( 1 ), dan jlo = 0.

    Voorbeeld: de aflopende reeks 7, 4, 2 en 1 levert de volgende test-
    resultaatwaarden op: (0, 4); (1, 4); (1.5, 3); (2, 3); (3, 2); (4, 2);
    (6, 1); (7, 1); (8, 0) }

    Function NextIndx( const x: Double; const Direction: TDirection ): Integer;
    {-Zoek, in een OPLOPEND geordende reeks de volgende waarde op afhankelijk
    van de zoekrichting (Direction).
    Het resultaat wordt verkregen met de functie "NextIndx". }

   {Voorbeeld: de oplopende reeks 1, 2, 4 en 7 levert de volgende test-
   resultaatwaarden op (Direction = Frwrd): (0, 1); (1, 2); (1.5, 2); (2, 3);
   (3, 3); (4, 4); (6, 4); (7, 0); (8, 0)
   Voorbeeld: de aflopende reeks 7, 4, 2 en 1 levert de volgende (ONBRUIKBARE)
   testresultaatwaarden op(Direction = Frwrd): (0, 1); (1, 1); (1.5, 1); (2, 1);
   (3, 1); (4, 1); (6, 1); (7, 2); (8, 2);

   Idem, maar dan (Direction = Bckwrd):
   opl. reeks:
     (0, 0); (1, 0); (1.5, 1); (2, 1); (3, 2); (4, 2); (6, 3); (7, 3); (8, 4)
   afl. reeks levert de volgende (ONBRUIKBARE) testresultaatwaarden op
     (0, 4); (1, 4); (1.5, 3); (2, 3); (3, 2); (4, 2); (6, 0); (7, 0); (8, 0)}

    Function NextIndxA( const x: Double; const Direction: TDirection ): Integer;
    {-Zoek, in een OPLOPEND geordende reeks de volgende waarde op afhankelijk
    van de zoekrichting (Direction). Afwijkend resultaat bij 'de randen' van de
    array. Het resultaat wordt verkregen met de functie "NextIndxA". }

   {Voorbeeld: de oplopende reeks 1, 2, 4 en 7 levert de volgende test-
   resultaatwaarden op (Direction = Frwrd): (0, 2); (1, 2); (1.5, 2); (2, 3);
   (3, 3); (4, 4); (6, 4); (7, 0); (8, 0)
   Voorbeeld: de aflopende reeks 7, 4, 2 en 1 levert de volgende test-
   resultaatwaarden op(Direction = Frwrd): (0, 0); (1, 0); (1.5, 4); (2, 4);
   (3, 3); (4, 3); (6, 2); (7, 2); (8, 2);

   Idem, maar dan (Direction = Bckwrd):
   opl. reeks:
     (0, 0); (1, 0); (1.5, 0); (2, 0); (3, 2); (4, 2); (6, 3); (7, 3); (8, 4)
   afl. reeks levert het volgende (ONBRUIKBARE) resultaat:
     (0, 4); (1, 4); (1.5, 3); (2, 3); (3, 2); (4, 2); (6, 0); (7, 0); (8, 0)}

    Function DstToNextXvalueA( const x: Double;
             const Direction: TDirection ): Double; Virtual;
    {-Afstand (dx) tot volgende waarde bij een OPLOPEND geordende reeks
     (t.b.v. TxyTable.DxTilNextYChange)}

    {Voorbeeld: de oplopende reeks 1, 2, 4 en 7 levert de volgende test-
    resultaatwaarden op (Direction = Frwrd): (0, 2); (1, 1); (1.5, 0.5); (2, 2);
    (3, 1); (4, 3); (6, 1); (7, 3.4E+0038); (8, 3.4E+0038)
    Voorbeeld: de aflopende reeks 7, 4, 2 en 1 levert de volgende (ONBRUIKBARE?)
    testresultaatwaarden op(Direction = Frwrd): (0, 3.4E+0038); (1, 3.4E+0038);
    (1.5, -0.5); (2, -1.0); (3, -1.0); (4, -2.0); (6, -2.0); (7, -3.0);
    (8, -4.0);

    Idem, maar dan (Direction = Bckwrd):
    opl. reeks:
      (0, -3.4E+0038); (1, -3.4E+0038); (1.5, -3.4E+0038); (2, -3.4E+0038);
      (3, -1); (4, -2); (6, -2); (7, -3); (8, -1)
    afl. reeks levert de volgende (ONBRUIKBARE) testresultaatwaarden op
      (0, 1); (1, 0); (1.5, 0.5); (2, 0); (3, 1); (4, 0); (6, -3.4E+0038);
      (7, -3.4E+0038); (8, -3.4E+0038)}

    Function DstToNextXvalue( const x: Double;
             const Direction: TDirection ): Double; Virtual;
    {-Afstand (dx) tot volgende waarde bij een OPLOPEND geordende reeks
     (t.b.v. TxyTable.DxTilNextYChange)}

    {Voorbeeld: de oplopende reeks 1, 2, 4 en 7 levert de volgende test-
    resultaatwaarden op (Direction = Frwrd): (0, 1); (1, 1); (1.5, 0.5); (2, 2);
    (3, 1); (4, 3); (6, 1); (7, 3.4E+0038); (8, 3.4E+0038)
    Voorbeeld: de aflopende reeks 7, 4, 2 en 1 levert de volgende (ONBRUIKBARE?)
    testresultaatwaarden op(Direction = Frwrd): (0, 7); (1, 6);
    (1.5, 5.5); (2, 5); (3, 4); (4, 3); (6, 1); (7, -3); (8, -4);

    Idem, maar dan (Direction = Bckwrd):
    opl. reeks:
      (0, -3.4E+0038); (1, -3.4E+0038); (1.5, -0.5); (2, -1.0); (3, -1.0);
      (4, -2.0); (6, -2.0); (7, -3.0); (8, -1.0)
    afl. reeks levert de volgende (ONBRUIKBARE) testresultaatwaarden op
      (0, 1.0); (1, 0.0); (1.5, 0.5); (2, 0.0); (3, 1.0); (4, 0.0);
      (6, -3.4E+0038); (7, -3.4E+0038); (8, -3.4E+0038)}

    Property Items[Index: Integer]: Double read Getx write Setx; default;
    Function IsAscending: Boolean; Virtual;
    Function Process( const ProcessType: TProcessType;
                      const Factor: Double ): Boolean; Virtual;
    {-True als er geen fout is opgetreden tijdens de verwerking}
    Procedure Sort( SortOrder: TSortOrder ); Virtual;
    Procedure SwapSortOrder; Virtual;
    Procedure Negate; Virtual;
    {-Keer het teken van de array om}

    Function GetDynArr: ParrayOfDouble; {-T.b.v. snelle 'clone' procedures}
    Function Getjlo: Integer;           {-T.b.v. snelle 'clone' procedures}
    Procedure Setjlo( const ajlo: Integer ); {-T.b.v. 'clone' procedures; geen controle!}
    Function Search( const I_x: Double; var I_index: Integer ): Boolean; Virtual;
      {-True als x gevonden. Er geldt dan: x[I_index] is x, anders I_index = 0}

  end;

  PLargeIntegerArray = ^TLargeIntegerArray;
  TLargeIntegerArray = Class( TComponent )
  private
  protected
    DynArr: array of Integer;
//    procedure DefinePropterties verwijderd: geeft moeilijk op te lossen
//    problemen in de werkomgeving
//    procedure DefineProperties(Filer: TFiler); override;
  public
    Constructor Create( NrOfElements: Integer; AOwner: TComponent );
                Overload;
    Constructor CreateF( NrOfElements: Integer; const Value: Integer; AOwner: TComponent );
                reintroduce;
    Constructor InitialiseFromTextFile( var f: TextFile; AOwner: TComponent );
    Destructor  Destroy; override;
//    procedure   ReadAllData( Reader: TReader );
//    procedure   WriteAllData( Writer: TWriter );
    Function    SaveToStream( SaveStream: TStream ): Boolean; Virtual;
    Function    LoadFromStream( LoadStream: TStream ): Boolean; Virtual;
    Function    Getx(i: Integer): Integer; Virtual;
    Function    NrOfElements: Integer;
    Procedure   Setx(i: Integer; const Value: Integer ); Virtual;
    Procedure   WriteToTextFile( var f: TextFile ); Virtual;
    Property    Items[Index: Integer]: Integer read Getx write Setx; default;
    Function    IsAscending: Boolean; Virtual;
    Procedure   Sort( SortOrder: TSortOrder ); Virtual;
    Procedure   SwapSortOrder; Virtual;
    Procedure   Negate; Virtual; {-Keer het teken van de array om}
  end;

  TDoubleArray = array of Double;
  TDoubleArrayDescendant = ( cDoubleArray, cDbleMtrxColindx, cDbleMtrxColAndRowIndx, cUngPar );
    {-Wordt gebruikt in 'WriteToOpenedTextFile' en 'Clone'}
  TDoubleMatrix = Class( TComponent )
  private
  protected
    DynMatrix: array of TDoubleArray;
//    procedure DefinePropterties verwijderd: geeft moeilijk op te lossen
//    problemen in de werkomgeving
//    procedure DefineProperties(Filer: TFiler); override;
  public
    Constructor Create( const NRows, NCols: Integer; AOwner: TComponent );
                reintroduce;
    Constructor CreateF( const NRows, NCols: Integer; const Value: Double;
                AOwner: TComponent ); {-Initialise and fill with Value}
    Constructor InitialiseFromTextFile( var f: TextFile; AOwner: TComponent ); overload;
    Constructor InitialiseFromTextFile( var f: TextFile; const WordDelims: CharSet;
      Const NrOfInitialLinesToScip: Integer; AOwner: TComponent ); Overload;
    procedure   ReadAllData( Reader: TReader );
    procedure   WriteAllData( Writer: TWriter );
    Destructor  Destroy; Override;
    Function    SaveToStream( SaveStream: TStream ): Boolean; Virtual;
    Function    LoadFromStream( LoadStream: TStream ): Boolean; Virtual;
    Function    LowLevelGetNRows: Integer; Virtual;
    Function    LowLevelGetNCols: Integer; Virtual;
    Function    LowLevelGetValue( const Row, Col: Integer): Double; Virtual;
    Function    GetNRows: Integer; Virtual;
    Function    GetNCols: Integer; Virtual;
    Function    GetValue( const Row, Col: Integer): Double; Virtual;
    Procedure   SetValue( const Row, Col: Integer; const Value: Double ); Virtual;
    Property    Items[ const Row, Col: Integer]: Double read GetValue write SetValue; default;
    Function    SumOfColumn( const Col: Integer ): Double; Virtual;
    Function    MinOfColumn( const Col: Integer ): Double; Virtual;
    Function    MaxOfColumn( const Col: Integer ): Double; Virtual;
    Function    SumOfRow( const Row: Integer ): Double; Virtual;
    Procedure   WriteToTextFile( var f: TextFile; const ColSeparator: Char ); Overload;
    Procedure   WriteToTextFile( const aFileName: String; const ColSeparator: Char ); OverLoad;
    Procedure   WriteDescendantTypeToTextFile( var f: TextFile ); Virtual;
    Procedure   GetSortRowsIndexArray( const Col: Integer; var indx: TLargeIntegerArray ); Virtual;
    Function    SortRows( const Col: Integer; const SortOrder: TSortOrder ): Integer; Virtual;
    Function    DescendantType: TDoubleArrayDescendant; Virtual;
      {-Nodig in 'Clone'}
    Function    Clone: TDoubleMatrix; Virtual;
      {-Returns a new instance of the TDoubleMatrix-class and copies the data into it}
    Function    GetCol( const Col: Integer ): TDoubleArray;
    Function    EstimateYLinInterpolation( {var LF: Text;} const x: Double; const ColX, ColY: Integer; var iError: Integer ): Double;
    {-Levert geïnterpoleerde y-waarde bij gegeven x-waarde, OP VOORWAARDE dat:
     -1- x-waarden in ColX zitten en y-waarde in ColY;
     -2- x-waarden OPLOPEND gesorteerd zijn;
     -3- er geen dubbele x-waarden zijn.
     Opmerking:
     -1- Dit is geen super snelle routine!; Gebruik voor snelheid xyTable;
     -2- ER VINDT GEEN CONTROLE PLAATS OP DE VOORWAARDEN DIE HIERVOOR ZIJN GENOEMD.
     -3- GEEN EXTRAPOLATIE.
    }
  end;

  {-TDoubleMatrix waarbij de 1-ste rij GESORTEERDE 'vertaal-sleutels' zijn}
  TDbleMtrxColindx = Class( TDoubleMatrix )
  private
  protected
  public
    Function GetColNr( const ColValue: Double ): Integer; Virtual;
    Function GetValue( const Row: Integer; const ColValue: Double ): Double;
             Reintroduce; Overload; Virtual;
      {-Key-waarden <= ColValue; geen extrapolatie}
    Function GetValue( const Row: Integer; const ColValue, NoMatchValue: Double ): Double;
             Reintroduce; Overload; Virtual;
      {-ColValue moet precies overeenstemmen met een waarde op de 1-ste rij,
        anders is het resultaat 'NoMatchValue'}
    Procedure SetValue( const Row: Integer; const ColValue, Value: Double );
             Reintroduce; Virtual;
    Function GetNRows: Integer; Override;
    Procedure SetKeyValue( const Col: Integer; const Value: Double ); Virtual;
    Function SumOfColumn( const ColValue: Double ): Double; Reintroduce; Virtual;
    Function SumOfRow( const Row: Integer ): Double; Override;
    Function DescendantType: TDoubleArrayDescendant; Override;
      {-Nodig in 'Clone'}
    Function Clone: TDbleMtrxColindx; Reintroduce; Virtual;
      {-Returns a new instance of the TDbleMtrxColindx-class and copies the
        data into it}
  end;

  {-TDoubleMatrix waarbij de 1-ste rij en 1-ste kolom GESORTEERDE
    'vertaal-sleutels' zijn }
  TDbleMtrxColAndRowIndx = Class( TDoubleMatrix )
  private
  protected
  public
    Function GetColNr( const ColValue: Double ): Integer; Virtual;
    Function GetRowNr( const RowValue: Double ): Integer; Virtual;
    Function GetUpColIndx( const ColValue: Double ): Integer; Virtual;
    Function GetUpRowIndx( const RowValue: Double ): Integer; Virtual;
    Function GetValue( const RowValue, ColValue: Double ): Double;
             Reintroduce; Overload; Virtual;
      {-Geen extrapolatie}
    Function NoValue: Double; Virtual;
    Function GetValue( const RowValue, ColValue, NoMatchValue: Double ): Double;
             Reintroduce; Overload; Virtual;
      {-(RowValue,ColValue) moeten precies overeenstemmen met een waarde op de
         1-ste rij resp. 1-ste kolom, anders is het resultaat 'NoMatchValue'}
    Procedure SetValue( const RowValue, ColValue, Value: Double );
             Reintroduce; Virtual;
    Procedure SetColKeyValue( const Col: Integer; const Value: Double ); Virtual;
    Procedure SetRowKeyValue( const Row: Integer; const Value: Double ); Virtual;
    Function SumOfColumn( const ColValue: Double ): Double; Reintroduce; Virtual;
    Function SumOfRow( const RowValue: Double ): Double; Reintroduce; Virtual;
    Function GetNRows: Integer; Override;
    Function GetNCols: Integer; Override;
    Procedure GetMinMaxIndexValues( var MinC, MaxC, MinR, MaxR: Double ); Virtual;
    Function GetValueByLinearInterpolation( const RowValue, ColValue:
             Double ): Double; Virtual;
    Function DescendantType: TDoubleArrayDescendant; Override;
      {-Nodig in 'Clone'}
    Function Clone: TDbleMtrxColAndRowIndx; Reintroduce; Virtual;
      {-Returns a new instance of the TDbleMtrxColAndRowIndx-class and copies
        the data into it}
  end;

  {-Triwaco puntenbestand in ung- en par- formaat}
  TDbleMtrxUngPar = Class( TDoubleMatrix )
  private
    Names: TStringList;
  protected
  public
     Constructor InitialiseFromTextFile( const FileName: String; AOwner: TComponent );
      {-Geen extrapolatie}
    Function NoValue: Double; Virtual;
    Function GetID( const RowValue: Integer ): Integer; Virtual;
    Function Getx( const RowValue: Integer ): Double; Virtual;
    Function Gety( const RowValue: Integer ): Double; Virtual;
    Function Getz( const RowValue: Integer ): Double; Virtual;
    Procedure SetID( const RowValue: Integer; const Value: Integer ); Virtual;
    Procedure Setx( const RowValue: Integer; const Value: Double ); Virtual;
    Procedure Sety( const RowValue: Integer; const Value: Double ); Virtual;
    Procedure Setz( const RowValue: Integer; const Value: Double ); Virtual;
    Function GetUngParName( const RowValue: Integer ): String; Virtual;
    Procedure SetUngParName( const RowValue: Integer; const aName: String ); Virtual;
    Function DescendantType: TDoubleArrayDescendant; Override;
      {-Nodig in 'Clone'}
    Function Clone: TDbleMtrxUngPar; Reintroduce; Virtual;
      {-Returns a new instance of the TDbleMtrxUngPar-class and copies
        the data into it}
    Procedure WriteToAviewTextFile( var f: TextFile ); Virtual;
  end;

  EErrorOpeningUngParFile = class( Exception );
  EUngParFileContainsNoPointValues = class( Exception );
  EErrorReadingPointsFromUngParFile = class( Exception );
  ResourceString
    sCouldNotOpenUngParFile = 'Could not open Ung- and Par- file: "%s".';
    sUngParFileContainsNoPointValues = 'Ung- and Par- file: "%s" has no point values.';
    sErrorReadingPointsFromUngParFile = 'Error reading points from Ung- and Par- file: "%s".';

Procedure Hunt( var xx: Array of Double; const n: Integer; const x: Double;
                  var jlo: Integer );
  {-Given an array xx[0..n-1] and a value x, returns a value
   jlo such that:
   * xx[jlo]   < x <= xx[jlo+1] (ascending array);
   * xx[jlo+1] < x <= xx[jlo] (descending array).
   The array must be monotonic, either increasing or in-
   creasing or decreasing. jlo=-1 or jlo=n-1 is returned to
   indicate that x is out of range. jlo on input is taken
   as the initial guess for jlo on output.

   Voorbeeld: de oplopende reeks 1, 2, 4 en 7 levert de volgende test-
   resultaatwaarden op: (0, -1); (1, -1); (1.5, 0); (2, 0); (3, 1); (4, 1);
   (6, 2); (7, 2); (8, 3)

   Aflopende arrays:
     - Getx( jlo+1 ) < x <= Getx( jlo )
     - als x <  Getx( NrOfElements ), dan jlo = NrOfElements;
     - als x >= Getx( 1 ), dan jlo = 0.

   Voorbeeld: de aflopende reeks 7, 4, 2 en 1 levert de volgende test-
   resultaatwaarden op: (0, 3); (1, 3); (1.5, 2); (2, 2); (3, 1); (4, 1);
   (6, 0); (7, 0); (8, -1) }

Procedure NextIndexA( var xx: Array of Double; const n: Integer;
         const x: Double; const Direction: TDirection; var jlo: Integer );
  {-Zoek, in een geordende reeks de volgende waarde op afhankelijk van de
    zoekrichting (Direction). Afwijkend resultaat bij 'de randen' van de array.
    Het resultaat is steeds: "TLargeRealArray.NextIndxA" - 1 }

Procedure NextIndex( var xx: Array of Double; const n: Integer;
          const x: Double; const Direction: TDirection; var jlo: Integer );
  {-Zoek, in een geordende reeks de volgende waarde op afhankelijk van de
    zoekrichting (Direction). Het resultaat is steeds:
    "TLargeRealArray.NextIndx" - 1 }

Procedure DistToNextXvalueA( var xx: Array of Double; const n: Integer;
         const x: Double; const Direction: TDirection; var jlo: Integer;
         var dx: Double );
  {-Afstand (dx) tot volgende waarde (t.b.v. TxyTable.DxTilNextYChange);
    zie ook "TLargeRealArray.DistToNextXvalueA"}

Procedure DistToNextXvalue( var xx: Array of Double; const n: Integer;
         const x: Double; const Direction: TDirection; var jlo: Integer;
         var dx: Double );
  {-Afstand (dx) tot volgende waarde (t.b.v. TxyTableLinInt.DxTilNextYChange);
    zie ook "TLargeRealArray.DstToNextXvalue"}

Procedure SortAscending( n: integer; var arr: Array of Double );
  {Sorts an array arr[0..n-1] into ascending numerical order using the Heapsort
   algorithm. n is input; ra is replaced on output b its sorted rearrangement}

Procedure ISortAscending( n: integer; var arr: Array of Integer );
  {Sorts an array arr[0..n-1] into ascending numerical order using the Heapsort
   algorithm. n is input; ra is replaced on output b its sorted rearrangement}


PROCEDURE polint( const n: integer; var xa,ya: Array of Double; const x: Double;
          VAR y, dy: Double; var IErr: Integer );
  {-Given arrays xa[0..n-1] and ya[0..n-1] and given a value x, this routine
    returns a value y and an error estimate dy. if P(x) is the polynomial of
    degree n-1 such that P(xa)=yai (i=1..n), then the returned value y=P(x)}

Procedure SwapDirection( var Direction: TDirection );

Procedure WriteStatInfo( var StatInfo: TStatInfoType; var f: TextFile );

{-Foutcodes LargeArrays: -10399..-10300}
Const
  cDoubleXValuesInRowPolInt = -10300;
  cXisOutOfRangeInEstimateYLinInterpolation = -10301;
  cStripNoDataValues = true;
  cIncludeNoDataValues = false;

procedure Register;

Implementation

Uses
  uError;

Const
  cNoDataValue = MinDouble;

Procedure WriteStatInfo( var StatInfo: TStatInfoType; var f: TextFile );
begin
  Writeln( f, 'StatInfo:' );
  with StatInfo do begin
    Writeln( f, 'sum = ', Sum );
    Writeln( f, 'Average = ', Average );
    Writeln( f, 'Perc5 = ', Perc5 );
    Writeln( f, 'Perc10 = ', Perc10 );
    Writeln( f, 'Perc25 = ', Perc25 );
    Writeln( f, 'Median = ', Median );
    Writeln( f, 'Perc75 = ', Perc75 );
    Writeln( f, 'Perc90 = ', Perc90 );
    Writeln( f, 'Perc95 = ', Perc95 );
  end;
end;

Procedure SwapDirection( var Direction: TDirection );
begin
  if ( Direction = FrWrd ) then
    Direction := BckWrd
  else
    Direction := FrWrd;
end;

Procedure DistToNextXvalueA( var xx: Array of Double; const n: Integer;
         const x: Double; const Direction: TDirection; var jlo: Integer;
         var dx: Double );
{Function TxyTable.DxTilNextYChange( const x: Double;
         const Direction: TDirection ): Double;
var
  i: Integer;
begin
  i := NextXindex( x, Direction );
  if ( i <> 0 ) then
    Result := Getx( i ) - x
  else begin
    if ( Direction = FrWrd ) then
      Result := MaxSingle
    else
      Result := -MaxSingle;
  end;
end;}
begin
  NextIndexA( xx, n, x, Direction, jlo );
  if ( jlo <> -1 ) then
    dx := xx[ jlo ] - x
  else begin
    if ( Direction = FrWrd ) then
      dx := MaxSingle
    else
      dx := -MaxSingle;
  end;
end;

Procedure DistToNextXvalue( var xx: Array of Double; const n: Integer;
         const x: Double; const Direction: TDirection; var jlo: Integer;
         var dx: Double );
begin
  NextIndex( xx, n, x, Direction, jlo );
  if ( jlo <> -1 ) then
    dx := xx[ jlo ] - x
  else begin
    if ( Direction = FrWrd ) then
      dx := MaxSingle
    else
      dx := -MaxSingle;
  end;
end;

Procedure NextIndexA( var xx: Array of Double; const n: Integer;
         const x: Double; const Direction: TDirection; var jlo: Integer );
{Function TxyTable.NextXindex( const x: Double;
                              const Direction: TDirection ): Integer;
var
  n: Integer;
begin
  n := NrOfElements;
  if ( n <= 1 ) then
    Result := 0
  else begin
    if ( Direction = FrWrd ) then begin
      Result := MaxI( DynArrX.Hnt( x ) + 1, 2 );
      if ( Result > n ) then
        Result := 0
      else begin
        if ( Getx( Result ) = x ) then
          Inc( Result );
        if ( Result > n ) then
          Result := 0
      end;
    end else begin
      Result := DynArrX.Hnt( x );
      if Result < 2 then
        Result := 0;
    end;
  end;
end;}
begin
  if ( n <= 1 ) then
    jlo := -1{0}
  else begin
    if ( Direction = FrWrd ) then begin
      Hunt( xx, n, x, jlo );
      jlo := Max( {DynArrX.Hnt( x )} jlo + 1, 1 );
      if ( jlo > n-1 ) then
        jlo := -1
      else begin
        if ( xx[ jlo ] = x ) then
          Inc( jlo );
        if ( jlo > n-1 ) then
          jlo := -1
      end;
    end else begin  {-Direction = BckWrd}
      Hunt( xx, n, x, jlo );
      if jlo < 1 then
        jlo := -1;
    end;
  end;
end;

procedure Hunt( var xx: Array of Double; const n: Integer; const x: Double;
                var jlo: Integer );
  var
    jm, jhi, inc: Integer;
    ascnd : Boolean;
  Label 1, 99;
  begin
    ascnd :=   (xx[n-1] > xx[0]);

    if (jlo <= -1) or (jlo > n-1) then
      begin
        jlo := -1; jhi := n;
      end
    else
      begin
        inc := 1;
        if (x > xx[jlo]) = ascnd then   {Hunt up}
          begin
            if (jlo=n-1) then goto 99;
            jhi := jlo + 1;
            while (x > xx[jhi]) = ascnd do begin {not done hunting}
              jlo:=jhi; inc:=inc+inc; jhi:=jlo+inc;
              if (jhi > n-1) then begin
                jhi := n; goto 1
              end; {if}
            end; {while}
          end
        else                 {Hunt down}
          begin
            if (jlo=0) then begin
              jlo := -1; goto 99
            end; {if}
            jhi := jlo; jlo := jhi - 1;
            while (x <= xx[jlo]) = ascnd do begin {not done hunting}
              jhi:=jlo; inc:=inc+inc;
              if (jhi>inc) then
                jlo := jhi-inc
              else
                begin
                  jlo := -1; goto 1
                end; {if}
            end; {while}
          end {if}
      end; {if}

1:  {Hunt is done; begin bisection phase}
    while (jhi-jlo <> 1) do begin
      jm := (jhi+jlo) div 2;
      if (x > xx[jm]) = ascnd then
        jlo := jm
      else
        jhi := jm;
    end; {while}

99: end; {Procedure Hunt}

Procedure SortAscending( n: integer; var arr: Array of Double );
Label 99;
var
   l,j,ir,i: integer;
   rra: Double;
begin
   if ( n <= 1 ) then exit;

   l := (n div 2)+1;
   ir := n;
   while true do begin
      if (l > 1) then begin
         l := l-1;
         rra := arr[l - 1 ]
      end else begin
         rra := arr[ir - 1 ];
         arr[ir - 1 ] := arr[1 - 1 ];
         ir := ir-1;
         if (ir = 1) then begin
            arr[1 - 1 ] := rra;
            goto 99
         end
      end;
      i := l;
      j := l+l;
      while (j <= ir) do begin
         if (j < ir) then
            if (arr[j - 1 ] < arr[j+1 - 1 ]) then j := j+1;
         if (rra < arr[j - 1 ]) then begin
            arr[i - 1 ] := arr[j - 1 ];
            i := j;
            j := j+j
         end else
            j := ir+1
      end;
      arr[i - 1 ] := rra
   end;
99:   end;

Procedure ISortAscending( n: integer; var arr: Array of Integer );
Label 99;
var
   l,j,ir,i: integer;
   rra: integer;
begin
   if ( n <= 1 ) then exit;

   l := (n div 2)+1;
   ir := n;
   while true do begin
      if (l > 1) then begin
         l := l-1;
         rra := arr[l - 1 ]
      end else begin
         rra := arr[ir - 1 ];
         arr[ir - 1 ] := arr[1 - 1 ];
         ir := ir-1;
         if (ir = 1) then begin
            arr[1 - 1 ] := rra;
            goto 99
         end
      end;
      i := l;
      j := l+l;
      while (j <= ir) do begin
         if (j < ir) then
            if (arr[j - 1 ] < arr[j+1 - 1 ]) then j := j+1;
         if (rra < arr[j - 1 ]) then begin
            arr[i - 1 ] := arr[j - 1 ];
            i := j;
            j := j+j
         end else
            j := ir+1
      end;
      arr[i - 1 ] := rra
   end;
99:   end;



PROCEDURE polint( const n: integer; var xa, ya: Array of Double;
                  const x: Double; VAR y, dy: Double; var IErr: Integer );
Label 99;
VAR
  ns, m, i: integer;
  w, hp, ho, dift, dif, den: Double;
  c, d: Array of Double;
BEGIN
  IErr := cNoError;
  if ( n = 1 ) then begin {-Besteed geen aandacht aan triviale gevallen}
    y  := ya[ 0 ];
    dy := 0;
    Exit;
  end;
  ns   := 1;
  dif  := abs( x - xa[ 0 ] );
  SetLength( c, n ); SetLength( d, n );
  FOR i := 0 TO n-1 DO BEGIN {-Find the index ns of the closest table entry}
    dift := abs( x - xa[ i ] );
    IF ( dift < dif ) THEN BEGIN
      ns := i;
      dif := dift
    END;
    c[ i ] := ya[ i ];       {-And initialise the tableau of c's and d's}
    d[ i ] := ya[ i ];
  END;
  y  := ya[ ns ];               {-Initial approximation to y}
  ns := ns - 1;
  FOR m := 0 TO n-2 DO BEGIN
    FOR i := 0 TO n-m-1 DO BEGIN
      ho  := xa[ i ] - x;
      hp  := xa[ i + m ] - x;
      w   := c[ i + 1 ] - d[ i ];
      den := ho - hp;
      IF ( den = 0.0 ) THEN BEGIN
        IErr := cDoubleXValuesInRowPolInt; Goto 99;
      END;
      den := w / den;
      d[ i ] := hp * den;
      c[ i ] := ho * den;
    END;
    IF ( ( 2 * ns ) < ( n - m - 1 ) ) THEN BEGIN
      dy := c[ ns ]
    END ELSE BEGIN
      dy := d[ ns-1 ];
      ns := ns-1
    END;
    y := y+dy
  END;

99:   SetLength( c, 0 ); SetLength( d, 0 );
END;

Constructor TLargeRealArray.Create( const NrOfElements: Integer;
            AOwner: TComponent );
begin
  Inherited Create( AOwner );
  Try
    SetLength( DynArr, NrOfElements );
  Except
    raise Exception.CreateFmt( 'Initialisation failed in: ' +
      '"TLargeRealArray.Create". NrOfElements= %d.', [ NrOfElements ] )
  end;
  jlo := NrOfElements div 2;
  NoDataIsSet := False;
  NoDataValue := cNoDataValue;
end;

Constructor TLargeRealArray.CreateFromOpenedTextFile( var f: TextFile;
  var LineNr: Integer; var Initiated: Boolean; AOwner: TComponent );
var
 I_NrOfElements, i: Integer;
 aValue: Double;
begin
  WriteToLogFileFmt( 'TLargeRealArray.CreateFromOpenedTextFile, LineNr= %d', [LineNr] );
  Initiated := false;
  Try
    Try
      Readln( f, I_NrOfElements );
      Inc( LineNr );
      Create( I_NrOfElements, AOwner );
      for i:=1 to NrOfElements do begin
        Readln( f, aValue );
        Inc( LineNr );
        Setx( i, aValue );
      end;
    Except
      SetLength( DynArr, 0 );
      WriteToLogFileFmt( 'TLargeRealArray.CreateFromOpenedTextFile: ERROR at line %d.', [LineNr] );
      Exit;
    End;
    Initiated := true;
    WriteToLogFile( 'TLargeRealArray.CreateFromOpenedTextFile: Done.')
  Finally
  End;
end;

Constructor TLargeRealArray.CreateFromCSVFile( FileName: String;
      HasColumnHeaders: Boolean; sep: Char; iColNr: Integer;
        AOwner: TComponent; var Initiated: Boolean );
var
  i, istart, iend, n: Integer;
  sg: TStringGrid;
  sl: TStringList;
begin
  WriteToLogFileFmt( 'Trying to initialise LargeRealArray from CSV file [%s]', [ FileName] );
  Initiated := False;
  Try
    Try
      sg := TStringGrid.Create(self);
      if not LoadCSV( Filename, HasColumnHeaders, sep, sg ) then
        raise Exception.CreateFmt('Error initialising from file [%s]. ', [FileName] );

      sl := TStringList.Create;

      for i := 0 to sg.RowCount-1 do
        sl.Add( Trim( sg.Rows[i][iColNr-1] ) );
      RemoveEmptyLinesFromStringList( sl);

      n := sl.Count;
      WriteToLogFileFmt( 'n = %d.', [n] );
      istart := 0; iend := n-1;
      if HasColumnHeaders then begin
        istart := 1;
        n := n-1;
      end;
      Create( n, AOwner );
      for i := istart to iend do begin
        //s:= sl[i];
        //WriteToLogFileFmt( 'i= %d; s=%s', [i,s] );
        Setx( i, StrToFloat( sl[i] ) );
      end;
    Initiated := True;
    WriteToLogFileFmt( 'LargeRealArray initiated from file [%s]', [FileName] );
    Except
      On E: Exception do begin
        WriteToLogFile( 'Error in TRealAdoSet.InitFromCSVFile.' );
      end;
    End;
  Finally
    FreeAndNil(sg);
  End;
end;

Procedure TLargeRealArray.SetNoDataValue( const iNoDataValue: Double );
begin
  NoDataValue := iNoDataValue;
  NoDataIsSet := True;
end;

Function TLargeRealArray.NoData( const i: Integer ): Boolean;
begin
  Result := NoDataIsSet and ( Getx( i ) = NoDataValue );
end;

Function TLargeRealArray.HasData( const i: Integer ): Boolean;
begin
  Result := Not NoData( i );
end;

Constructor TLargeRealArray.CreateF( const NrOfElements: Integer;
            const Value: Double; AOwner: TComponent );
var
  i: Integer;
begin
  Create( NrOfElements, AOwner );
  for i:=1 to NrOfElements do
    Setx( i, Value );
end;

Function TLargeRealArray.Search( const I_x: Double; var I_index: Integer ): Boolean;
      {-True als x gevonden. Er geldt dan: x[I_index] is x, anders I_index=0}
var
  i: integer;
begin
  Result := false; I_index := 0;
  i := 1;
  while ( i <= NrOfElements ) and ( not Result ) do begin
    Result := (I_x = DynArr[ i-1 ]);
    if Result then
      I_index := i
    else
      Inc( i );
  end;
end;

Function TLargeRealArray.DstToNextXvalueA( const x: Double;
         const Direction: TDirection ): Double;
begin
  DistToNextXvalueA( DynArr, NrOfElements, x, Direction, jlo, Result );
end;

Function TLargeRealArray.DstToNextXvalue( const x: Double;
         const Direction: TDirection ): Double;
begin
  DistToNextXvalue( DynArr, NrOfElements, x, Direction, jlo, Result );
end;

Destructor TLargeRealArray.Destroy;
begin
  SetLength( DynArr, 0 );
  Inherited;
end;

Function TLargeRealArray.Getx(i: Integer): Double;
begin
  Try
    Getx := DynArr[ i-1 ];
  Except
    on ERangeError do
      raise Exception.CreateFmt( 'Index out of range in ' +
      '"TLargeRealArray.Getx": %d; (min=1; max= %d).', [ i, NrOfElements ] )
    else
      raise Exception.Create('Onbekende fout in "TLargeRealArray.Getx". ');
  end;
end;

Function TLargeRealArray.NrOfElements: Integer;
begin
    NrOfElements := High (DynArr) + 1;
end;

Function TLargeRealArray.IsAscending: Boolean;
begin
  Result := ( NrOfElements > 1 ) and ( Items[ 1 ] < Items[ 2 ] );
end;

Procedure TLargeRealArray.Setx( i: Integer; const Value: Double );
begin
  Try
    DynArr[ i-1 ] := Value;
  Except
    on ERangeError do
      raise Exception.CreateFmt( 'Index out of range in ' +
      '"TLargeRealArray.Setx": %d; (min=1; max= %d).', [ i, NrOfElements ] )
    else
      raise Exception.Create('Onbekende fout in "TLargeRealArray.Setx". ');
  end;
end;

Function TLargeRealArray.GetDynArr: ParrayOfDouble;
begin
  Result := @DynArr;
end;

Function TLargeRealArray.Getjlo: Integer;
begin
  Result := jlo;
end;

Procedure TLargeRealArray.Setjlo( const ajlo: Integer );
begin
  jlo := ajlo;
end;

Function TLargeRealArray.Process( const ProcessType: TProcessType;
              const Factor: Double ): Boolean;
var
  i, n: Integer;
begin
  Result := False;
  n      := NrOfElements;
  Try
    for i:=1 to n do begin
      if HasData( i ) then begin
        case ProcessType of
          Divide:
            begin
              if Factor = 0 then
                exit
              else
                Setx( i, Getx( i ) / Factor );
            end;
          Multiply:  Setx( i, Getx( i ) * Factor );
          Substract: Setx( i, Getx( i ) - Factor );
          Add: Setx( i, Getx( i ) + Factor );
          SetValue: Setx( i, Factor );
        end;
      end; {-if ( not NoData( i ) )}
    end; {-for i:=1 to n }
  Except
    Exit;
  end;
  Result := True;
end;

Function TLargeRealArray.NrOfDataValues: Integer;
var
  i, n: Integer;
begin
  Result := 0;
  n      := NrOfElements;
  for i:=1 to n do
    if HasData( i ) then Inc( Result );
end;

Function TLargeRealArray.NrOfDataValues( const MinIndex, MaxIndex: Integer ): Integer;
var
  i, n, ifirst, ilast: Integer;
begin
  n := NrOfElements;
  if ( ( MinIndex <= 1 ) and ( MaxIndex >= n ) ) then begin
    Result := NrOfDataValues;
  end else if ( MinIndex > n ) or ( MaxIndex < 1 ) then begin
    Result := 0;
  end else begin
    Result := 0;
    ifirst := Min( Max( MinIndex, 1 ), n );
    ilast  := Max( Min( MaxIndex, n ), 1 );
    for i:=ifirst to ilast do
      if HasData( i ) then Inc( Result );
  end;
end;

Function TLargeRealArray.Full: Boolean;
var
  n: Integer;
begin
  n := NrOfElements;
  Result := ( n > 0 ) and ( n = NrOfDataValues );
end;

Function TLargeRealArray.GetSum( var NrOfValuesEvaluated: Integer; var ResultSum: Double ): Boolean;
var
  i,n: Integer;
begin
  NrOfValuesEvaluated := 0;
  n := NrOfElements;
  ResultSum := 0;
  for i:=1 to n do begin
    if HasData( i ) then begin
      ResultSum := ResultSum + Getx( i );
      Inc( NrOfValuesEvaluated );
    end;
  end;
  Result := ( NrOfValuesEvaluated > 0 );
end;

Constructor TLargeRealArray.CreateByCopy( var aLargeRealArray: TLargeRealArray;
  const MinIndex, MaxIndex: Integer; StripNoDataValues: boolean; AOwner: TComponent );
var
  i, j, n, ifirst, ilast, m: Integer;
begin
  n := aLargeRealArray.NrOfElements;
  ifirst := Min( Max( MinIndex, 1 ), n );
  ilast  := Max( Min( MaxIndex, n ), 1 );
  {ShowMessage( 'ifirst, ilast: ' + inttostr( ifirst ) + ' ' +  inttostr( ilast ));}

  if StripNoDataValues then
    m := aLargeRealArray.NrOfDataValues( MinIndex, MaxIndex )
  else
    m := ilast - ifirst + 1;

  {ShowMessage( 'm= '+ inttostr( m ) );}

  Create( m, AOwner );
  j := 1;
  for i:=ifirst to ilast do begin
    if not StripNoDataValues then begin
      Setx( j, aLargeRealArray[ i ] ); Inc( j );
    end else begin
      if aLargeRealArray.HasData( i ) then begin
        Setx( j, aLargeRealArray[ i ] ); Inc( j );
      end;
    end;
  end;
  jlo := 1;
  NoDataIsSet := aLargeRealArray.NoDataIsSet;
  NoDataValue := aLargeRealArray.NoDataValue;
end;

Function TLargeRealArray.GetStatInfo( var NrOfValuesEvaluated: Integer; var StatInfo: TStatInfoType ): Boolean;
const
  NoResult: TStatInfoType = (
    Sum: cNoDataValue;
    Average: cNoDataValue;
    Median: cNoDataValue;
    Perc5: cNoDataValue;
    Perc10: cNoDataValue;
    Perc25: cNoDataValue;
    Perc75: cNoDataValue;
    Perc90: cNoDataValue;
    Perc95: cNoDataValue );
var
  Buf: TLargeRealArray;
  function SetToValidIndex( i: Integer) : Integer;
  begin
    Result := Min( Max( i, 1 ), Buf.NrOfElements );
  end;
  Function GetDuurlijnValue( Fraction : Double ): Double;
  begin
    Result := Buf[ SetToValidIndex( Round( Fraction * Buf.NrOfElements ) ) ];
  end;
begin
  Result := false;
  StatInfo := NoResult;
  NrOfValuesEvaluated := 0;
  if ( NrOfDataValues = 0 ) then
    Exit;

  if not GetSum( NrOfValuesEvaluated, StatInfo.Sum ) then
    Exit;

  StatInfo.Average := StatInfo.Sum / NrOfValuesEvaluated;

  Buf := TLargeRealArray.CreateByCopy( self, 1, NrOfElements, cStripNoDataValues, self );
  Buf.Sort( Ascending );
  with StatInfo do begin
    Median := GetDuurlijnValue( 0.5 );
    Perc5 := GetDuurlijnValue( 0.05 );
    Perc10 := GetDuurlijnValue( 0.1 );
    Perc25 := GetDuurlijnValue( 0.25 );
    Perc75 := GetDuurlijnValue( 0.75 );
    Perc90 := GetDuurlijnValue( 0.90 );
    Perc95 := GetDuurlijnValue( 0.95 );
  end;
  Buf.Free;
  Result := true;
end;

Procedure NextIndex( var xx: Array of Double; const n: Integer;
          const x: Double; const Direction: TDirection; var jlo: Integer );
{Function TxyTableLinInt.NextXindex( const x: Double;
         const Direction: TDirection ): Integer;
begin
  if ( NrOfElements <= 1 ) then
    Result := 0
  else begin
    if ( Direction = FrWrd ) then begin
      if ( x >= Getx( 1 ) ) then
        Result := Inherited NextXindex( x, Direction )
      else
        Result := 1;
    end else begin
      if ( x > Getx( 2 ) ) then
        Result := Inherited NextXindex( x, Direction )
      else
        Result := DynArrX.Hnt( x );
    end;
  end;
end;}
begin
  if ( n <= 1 ) then
    jlo := -1
  else begin
    if ( Direction = FrWrd ) then begin
      if ( x >= xx[ 0 ] ) then
        NextIndexA( xx, n, x, Direction, jlo )
      else
        jlo := 0;
    end else begin  {-Direction = BckWrd}
      if ( x > xx[ 1 ] ) then
        NextIndexA( xx, n, x, Direction, jlo )
      else
        Hunt( xx, n, x, jlo );
    end;
  end;
end;

Procedure TLargeRealArray.Sort( SortOrder: TSortOrder );

begin
  if ( SortOrder = Ascending ) then
    SortAscending( NrOfElements, DynArr )
  else begin
    Negate;
    SortAscending( NrOfElements, DynArr );
    Negate;
  end;
end;

Procedure TLargeRealArray.SwapSortOrder;
begin
  if IsAscending then
    Sort( Descending )
  else
    Sort( Ascending );
end;

Procedure TLargeRealArray.Negate;
var
  i, n: Integer;
begin
  n := NrOfElements;
  for i:=0 to n-1 do
    DynArr[ i ] := -DynArr[ i ];
end;

Function TLargeRealArray.NextIndxA( const x: Double;
         const Direction: TDirection ): Integer;
begin
  NextIndexA( DynArr, NrOfElements, x, Direction, jlo );
  Result := ( jlo + 1 );
end;

Function TLargeRealArray.NextIndx( const x: Double;
         const Direction: TDirection ): Integer;
begin
  NextIndex( DynArr, NrOfElements, x, Direction, jlo );
  Result := ( jlo + 1 );
end;

Constructor TLargeIntegerArray.Create( NrOfElements: Integer;
                                       AOwner: TComponent );
begin
  Inherited Create( AOwner );
  Try
    SetLength( DynArr, NrOfElements );
  Except
    raise Exception.CreateFmt( 'Initialisation failed in: ' +
      '"TLargeIntegerArray.Create". NrOfElements= %d.', [ NrOfElements ] )
  end;
end;

Procedure TLargeIntegerArray.Sort( SortOrder: TSortOrder );
begin
  if ( SortOrder = Ascending ) then
    ISortAscending( NrOfElements, DynArr )
  else begin
    Negate;
    ISortAscending( NrOfElements, DynArr );
    Negate;
  end;
end;

Procedure TLargeIntegerArray.SwapSortOrder;
begin
  if IsAscending then
    Sort( Descending )
  else
    Sort( Ascending );
end;

Procedure TLargeIntegerArray.Negate;
var
  i, n: Integer;
begin
  n := NrOfElements;
  for i:=0 to n-1 do
    DynArr[ i ] := -DynArr[ i ];
end;

Function TLargeIntegerArray.IsAscending: Boolean;
begin
  Result := ( NrOfElements > 1 ) and ( Items[ 1 ] < Items[ 2 ] );
end;

Constructor TLargeIntegerArray.CreateF( NrOfElements: Integer; const Value: Integer; AOwner: TComponent );
var
  i: Integer;
begin
  Create( NrOfElements, AOwner );
  for i:=1 to NrOfElements do
    Setx( i, Value );
end;

Constructor TLargeIntegerArray.InitialiseFromTextFile( var f: TextFile;
  AOwner: TComponent );
var
  NrOfElements, i, aValue: Integer;
begin
  Try
    WriteToLogFile( 'Initialising LargeIntegerArray from textFile.' );
    Readln( f, NrOfElements );
    Create( NrOfElements, AOwner );
    for i:= 1 to NrOfElements do begin
      Readln( f, aValue ); Setx( i, aValue );
    end;
    WriteToLogFileFmt( 'LargeIntegerArray initialised with %d elements', [NrOfElements] );
  Except
    HandleError( 'Error initialising LargeIntegerArray from textFile.', true );
  end;
end;

Destructor TLargeIntegerArray.Destroy;
begin
  SetLength( DynArr, 0 );
  Inherited;
end;

Function TLargeIntegerArray.Getx(i: Integer): Integer;
begin
  Try
    Getx := DynArr[ i-1 ];
  Except
    on ERangeError do
      raise Exception.CreateFmt( 'Index out of range in ' +
      '"TLargeIntegerArray.Getx": %d; (min=1; max= %d).', [ i, NrOfElements ] )
    else
      raise Exception.Create('Onbekende fout in "TLargeIntegerArray.Getx". ');
  end;
end;

Procedure TLargeIntegerArray.WriteToTextFile( var f: TextFile );
var
  i, n: Integer;
begin
  n := NrOfElements;
  Writeln( f, n );
  for i:=1 to n do begin
    Writeln( f, Getx( i ) );
  end;
end;

Function TLargeIntegerArray.NrOfElements: Integer;
begin
    NrOfElements := Length( DynArr );
end;

Procedure TLargeIntegerArray.Setx( i: Integer; const Value: Integer );
begin
  Try
    DynArr[ i-1 ] := Value;
  Except
    on ERangeError do
      raise Exception.CreateFmt( 'Index out of range in ' +
      '"TLargeIntegerArray.Setx": %d; (min=1; max= %d).', [ i, NrOfElements ] )
    else
      raise Exception.Create('Onbekende fout in "TLargeIntegerArray.Setx". ');
  end;
end;

//Procedure TLargeIntegerArray.DefineProperties(Filer: TFiler);
//begin
//  inherited DefineProperties(Filer);
  { Define new properties and reader/writer methods }
//  Filer.DefineProperty('LargeIntegerArrayData', ReadAllData, WriteAllData, True );
//end;

//procedure TLargeIntegerArray.WriteAllData( Writer: TWriter );
//begin
//  Writer.WriteInteger(NrOfElements);
//  ShowMessage( 'Schrijf ' + IntToStr( NrOfElements ) + ' elements.' );
//  Writer.Write( DynArr, SizeOf( DynArr ) );
//end;

//procedure TLargeIntegerArray.ReadAllData( Reader: TReader );
//var
//  n: Integer;
//begin
//  n := Reader.ReadInteger;
//  SetLength( DynArr, n );
//  ShowMessage( 'Lees ' + IntToStr( NrOfElements ) + ' elements.' );
//  Reader.Read( DynArr, SizeOf( DynArr ) );
//end;

Function TLargeIntegerArray.SaveToStream( SaveStream: TStream ): Boolean;
var
  n: Integer;
begin
  Result := true;
  Try
    n := NrOfElements;
    SaveStream.Write( n, Sizeof( Integer ) );
    SaveStream.Write( DynArr, SizeOf( DynArr ) );
  Except
    Result := false;
  End;
end;

Function TLargeIntegerArray.LoadFromStream( LoadStream: TStream ): Boolean;
var
  n: Integer;
begin
  Result := true;
  Try
    LoadStream.Read( n, SizeOf( n ) );
    SetLength( DynArr, n );
    LoadStream.Read( DynArr, SizeOf( DynArr ) );
  Except
    Result := false;
  End;
end;

Function TLargeRealArray.Hnt( x: Double ): Integer;
var
  n: Integer;
begin
  n := NrOfElements;
  Hunt( DynArr, n, x, jlo );
  Result := ( jlo + 1 );
end;

//Procedure TLargeRealArray.DefineProperties(Filer: TFiler);
//begin
//  inherited DefineProperties(Filer);
  { Define new properties and reader/writer methods }
//  Filer.DefineProperty('LargeRealArrayData', ReadAllData, WriteAllData, True );
//end;

Procedure TLargeRealArray.WriteToTextFile( var f: TextFile );
var i: Integer;
begin
  WriteToLogFileFmt( 'TLargeRealArray.WriteToTextFile: %d elements.', [NrOfElements] );
  Writeln( f, NrOfElements );
  for i := 1 to NrOfElements do
    Writeln( f, Getx( i ) );
  WriteToLogFile( 'TLargeRealArray.WriteToTextFile: done.' );
end;

//procedure TLargeRealArray.WriteAllData( Writer: TWriter );
//begin
//  Writer.WriteInteger(NrOfElements);
//  Writer.WriteInteger(jlo);
  {if NoDataIsSet then
    Writer.WriteInteger( 1 )
  else
    Writer.WriteInteger( 0 );}
//  Writer.WriteBoolean( NoDataIsSet );
//  Writer.WriteDouble( NoDataValue );
//  ShowMessage( 'Schrijf dan nu ' + IntToStr( NrOfElements ) + ' elements.' );
//    Writer.Write( DynArr, SizeOf( DynArr ) );
//  ShowMessage( 'Done' );
//end;

//procedure TLargeRealArray.ReadAllData( Reader: TReader );
//var
//  n{, i}: Integer;
//begin
//  ShowMessage( 'Lees nu n' );
//  n := Reader.ReadInteger;
//  ShowMessage( 'Lees nu jlo' );
//  jlo := Reader.ReadInteger;
//  ShowMessage( 'Lees nu i' );
{  i := Reader.ReadInteger;
  if i = 1 then
    NoDataIsSet := true
  else
    NoDataIsSet := false;}
//  NoDataIsSet := Reader.ReadBoolean;
//  ShowMessage( 'Lees nu NoDataValue' );
//  NoDataValue := Reader.ReadDouble;
//  SetLength( DynArr, n );
//  ShowMessage( 'Lees dan nu' + IntToStr( NrOfElements ) + ' elements.' );
//  Reader.Read( DynArr, SizeOf( DynArr ) );
//end;

Function TLargeRealArray.SaveToStream( SaveStream: TStream ): Boolean;
var
  n: Integer;
begin
  Result := true;
  Try
    n := NrOfElements;
    SaveStream.Write( n, Sizeof( Integer ) );
    SaveStream.Write( jlo, Sizeof( jlo ) );
    SaveStream.Write( NoDataIsSet, Sizeof( NoDataIsSet ) );
    SaveStream.Write( NoDataValue, Sizeof( NoDataValue ) );
    SaveStream.WriteBuffer( Pointer( DynArr )^, n * SizeOf( Double ) );
  Except
    Result := false;
  End;
end;

Function TLargeRealArray.LoadFromStream( LoadStream: TStream ): Boolean;
var
  n: Integer;
begin
  Result := true;
  Try
    LoadStream.Read( n, SizeOf( n ) );
    LoadStream.Read( jlo, SizeOf( jlo ) );
    LoadStream.Read( NoDataIsSet, SizeOf( NoDataIsSet ) );
    LoadStream.Read( NoDataValue, SizeOf( NoDataValue ) );
    SetLength( DynArr, n );
    LoadStream.ReadBuffer( Pointer( DynArr )^, n*SizeOf( Double ) );
  Except
    Result := false;
  End;
end;

Constructor TDoubleMatrix.Create( const NRows, NCols: Integer;
            AOwner: TComponent );
//var
//  i: Integer;
begin
  Inherited Create( AOwner );
  Try
//    SetLength( DynMatrix, NRows );
//    for i:=0 to NRows-1 do
//      SetLength( DynMatrix[ i ], NCols );
    SetLength( DynMatrix, NRows, NCols );
  Except
    raise Exception.CreateFmt( 'Initialisation failed in: ' +
      '"TDoubleMatrix.Create". NRows, NCols= %d, %d', [ NRows, NCols ] )
  end;
end;

Constructor TDoubleMatrix.CreateF( const NRows, NCols: Integer;
            const Value: Double; AOwner: TComponent );
var
  i, j: Integer;
begin
  Create( NRows, NCols, AOwner );
  for i:=1 to NRows do
    for j:=1 to NCols do
      SetValue( i, j, Value );
end;

Destructor TDoubleMatrix.Destroy;
// var i: Integer;
begin
//  for i:=0 to GetNRows-1 do
//    SetLength( DynMatrix[ i ], 0 );
//    SetLength( DynMatrix, 0 );
  SetLength( DynMatrix, 0, 0 );
  Inherited;
end;

Function TDoubleMatrix.EstimateYLinInterpolation( {var LF: Text;} const x: Double; const ColX, ColY: Integer; var iError: Integer ): Double;
var
  i, NRows: Integer;
  aValue: Double;
begin
  iError := cNoError;
  NRows := GetNRows;

  Try
    if ( x <= GetValue( 1, ColX ) ) then begin
      Result := GetValue( 1, ColY );
      if ( x < GetValue( 1, ColX ) ) then
        iError := cXisOutOfRangeInEstimateYLinInterpolation;
    end else if ( x >= GetValue( NRows, ColX ) ) then begin
      Result := GetValue( NRows, ColY );
      if ( x > GetValue( NRows, ColX ) ) then
        iError := cXisOutOfRangeInEstimateYLinInterpolation;
    end else begin
      i := 1;
      Repeat
        Inc( i );
        aValue := GetValue( i, ColX );
        {Writeln( lf, i, ' ', x, ' ', aValue, ' test1' );}
      until ( (i = NRows) or ( x < aValue ) );
      Result := GetValue( i-1, ColY ) + ( GetValue( i, ColY ) - GetValue( i-1, ColY ) ) *
              ( x - GetValue( i-1, ColX ) ) / (GetValue( i, ColX ) - GetValue( i-1, ColX ));
      {Writeln( lf, 'Result = ', Result );}
    end;
  except
    Result := cUnknownError;
  end;
end;

Procedure TDoubleMatrix.GetSortRowsIndexArray( const Col: Integer; var indx: TLargeIntegerArray );
LABEL 99;
VAR
   n, l,j,ir,indxt,i: integer;
   q: Double;
BEGIN
   n := GetNRows;
   FOR j := 1 TO n DO BEGIN
      indx[j] := j
   END;
   l := (n DIV 2) + 1;
   ir := n;
   WHILE true DO BEGIN
      IF (l > 1) THEN BEGIN
            l := l-1;
            indxt := indx[l];
            q := GetValue( indxt, Col ); {arrin[indxt]}
      END ELSE BEGIN
         indxt := indx[ir];
         q := GetValue( indxt, Col );  {arrin[indxt];}
         indx[ir] := indx[1];
         ir := ir-1;
         IF (ir = 1) THEN BEGIN
            indx[1] := indxt;
            GOTO 99
         END
      END;
      i := l;
      j := l+l;
      WHILE (j <= ir) DO BEGIN
         IF (j < ir) THEN BEGIN
             IF ( GetValue(indx[j],Col) {arrin[indx[j]]} < GetValue(indx[j+1],Col) {arrin[indx[j+1]]}) THEN j := j+1
         END;
         IF (q < GetValue(indx[j],Col){arrin[indx[j]]}) THEN BEGIN
            indx[i] := indx[j];
            i := j;
            j := j+j
         END ELSE
            j := ir+1
      END;
      indx[i] := indxt
   END;
99:   END;

Function TDoubleMatrix.SortRows( const Col: Integer; const SortOrder: TSortOrder ): Integer;
var
  indx: TLargeIntegerArray;
  wksp: TDoubleMatrix;
  i, j, k, NRows, NCols: Integer;
begin
  Result := cUnknownError;
  Try
    NRows := GetNRows;
    NCols := GetNCols;
    indx := TLargeIntegerArray.Create( NRows, self );
    GetSortRowsIndexArray( Col, indx );
    wksp := Clone;
    for i:=1 to NRows do begin
      if SortOrder = Ascending then
        k := indx[ i ]
      else
        k := indx[ NRows-i+1 ];
      for j:=1 to NCols do begin
        SetValue( i, j, wksp[ k, j ] );
      end;
    end;
    wksp.Free;
    indx.free;
    Result := cNoError;
  except
  end;
end;

Function TDoubleMatrix.GetCol( const Col: Integer ): TDoubleArray;
var
  i, n: Integer;
begin
  n := GetNRows;
  SetLength( Result, n );
  for i:=1 to n do
    Result[ i-1 ] := LowLevelGetValue( i, Col );
end;

Function TDoubleMatrix.LowLevelGetValue( const Row, Col: Integer): Double;
begin
  Try
    Result := DynMatrix[ Row-1 ][ Col-1];
  Except
    on ERangeError do
      raise Exception.Create( 'Index out of range in ' +
                                 '"TDoubleMatrix.GetValue".' )
    else
      raise Exception.Create('Onbekende fout in "TDoubleMatrix.GetValue". ');
  end;
end;

Function TDoubleMatrix.GetValue( const Row, Col: Integer): Double;
begin
  Result := LowLevelGetValue( Row, Col );
end;

Function TDoubleMatrix.LowLevelGetNRows: Integer;
begin
  Result := Length( DynMatrix );
end;

Function TDoubleMatrix.LowLevelGetNCols: Integer;
begin
  if LowLevelGetNRows > 0 then
    Result := Length( DynMatrix[ 0 ] )
  else
    Result := 0;
end;

Function TDoubleMatrix.GetNRows: Integer;
begin
  Result := LowLevelGetNRows;
end;

Function TDoubleMatrix.GetNCols: Integer;
begin
  Result := LowLevelGetNCols;
end;

Procedure TDoubleMatrix.SetValue( const Row, Col: Integer; const Value: Double );
begin
  Try
    DynMatrix[ Row-1 ][ Col-1] := Value;
  Except
    on ERangeError do
      raise Exception.Create( 'Index out of range in ' +
                                 '"TDoubleMatrix.SetValue".' )
    else
      raise Exception.Create('Onbekende fout in "TLargeIntegerArray.Setx". ');
  end;
end;

Constructor TDoubleMatrix.InitialiseFromTextFile( var f: TextFile;
            AOwner: TComponent );
var
  NRows, NCols, i, j, NrOfIntervals: Integer;
  Start, Stop, dt: Double;
begin
  WriteToLogFile( 'Initialise TDoubleMatrix (or descendant) from text-file.' );
  Try
    WriteToLogFile( 'Inherited Create.' );
    Inherited {Create( AOwner )};
    Read( f, NRows ); WriteToLogFileFmt( 'Nr of rows= %d', [NRows] );
    if ( NRows > 0 ) then begin
      Readln( f, NCols );
      NCols := Max( NCols, 0 );
      WriteToLogFileFmt( 'Nr of cols= %d', [NCols] );
      WriteToLogFileFmt( 'NRows=%d; NCols=%d.', [NRows, NCols] );

      SetLength( DynMatrix, NRows, NCols );
      for i:=0 to NRows-1 do begin
//        SetLength( DynMatrix[ i ], NCols );
        {Write( lf, 'i,Matrix[1-NCols]: ', i+1:6, ' ' );}
        for j:=0 to NCols-1 do begin
          Read( f, DynMatrix[ i ][ j ] );
          {Write( lf, FloatToStrF( DynMatrix[ i ][ j ], ffExponent, 8, 2 ), ' ' );}
        end;
        Readln( f ); {Writeln( lf );}
      end;
      WriteToLogFile( 'All values read.' );
    end else if ( NRows < 0 ) then begin
      WriteToLogFile( 'Equidistant values on row.' );
      Readln( f );
      Readln( f, Start, Stop );
      if ( Start <> Stop ) then begin
        NrOfIntervals := -NRows;
      end else begin
        NrOfIntervals := 0;
      end;
      NCols := NrOfIntervals + 1;
      NRows := 1;
      WriteToLogFileFmt( 'NRows=%d; NCols=%d.', [NRows, NCols] );
      SetLength( DynMatrix, NRows );
      SetLength( DynMatrix[ 0 ], NCols );
      if ( NrOfIntervals > 0 ) then
        dt := ( Stop - Start ) / NrOfIntervals
      else
        dt := 0;
      for j:=0 to NCols-1 do begin
        DynMatrix[ 0 ][ j ] := Start + j * dt;
        {Writeln( lf, 'Matrix[0,', j, ']= ', FloatToStrF( DynMatrix[ 0 ][ j ], ffExponent, 8, 2 ) );}
      end;
      WriteToLogFile( 'All values read.' );
    end else begin
      WriteToLogFile( 'Single value on row.' );
      Readln( f );
      Readln( f, Start );
      NCols := 1;
      NRows := 1;
      WriteToLogFileFmt( 'NRows=%d; NCols=%d.', [NRows, NCols] );
      SetLength( DynMatrix, NRows );
      SetLength( DynMatrix[ 0 ], NCols );
      DynMatrix[ 0 ][ 0 ] := Start;
      WriteToLogFile( 'Matrix[0,0]= ' + FloatToStrF( DynMatrix[ 0 ][ 0 ], ffExponent, 8, 2 ) );
      WriteToLogFile( 'All values read.' );
    end;
  Except
    HandleError( 'Initialisation failed in: ' + '"TDoubleMatrix.InitialiseFromTextFile".', true );
  end;
end;

Constructor TDoubleMatrix.InitialiseFromTextFile( var f: TextFile; const WordDelims: CharSet;
      Const NrOfInitialLinesToScip: Integer; AOwner: TComponent );
var
  NRows, NCols, i, j, Len: Integer;
  aNumber: Double;
  Regel, S: String;
  Leesfout: Boolean;
begin
  WriteToLogFile( 'Initialise TDoubleMatrix (or descendant) from text-file.' );
  Try
    Inherited Create( AOwner );

    {-Tel het aantal getallen per regel}
    for i:=1 to NrOfInitialLinesToScip+1 do
      Readln( f, Regel );

    Leesfout := false;
    NCols := 0; i := 1;
    repeat
      try
        S := ExtractWord( i, Regel, WordDelims, Len );
        if ( S <> '' ) then begin
          aNumber := StrToFloat ( S );
          Inc( NCols ); Inc( i );
        end else begin
          raise Exception.Create( '' );
        end;
      except
        Leesfout := true;
      end;
    until ( ( Eoln( f ) ) or Leesfout );

    if NCols = 0 then begin
      raise Exception.Create( 'NCols = 0 in TDoubleMatrix.InitialiseFromTextFile.' );
    end;

    {-Tel het aantal regels}
    Leesfout := false;
    NRows := 1;
    repeat
      try
        Readln( f, Regel );
        for j:=1 to NCols do begin
          S := ExtractWord( j, Regel, WordDelims, Len );
          if ( Len > 0 ) then begin
            aNumber := StrToFloat ( S );
          end else begin
            raise Exception.Create( '' );
          end;
        end;
        Inc( NRows );
      except
        Leesfout := true;
      end;
    until ( ( Eoln( f ) ) or Leesfout );
    WriteToLogFileFmt( 'NRows=%d; NCols=%d.', [NRows, NCols] );

    {-Vul de matrix}
    SetLength( DynMatrix, NRows, NCols );
    Reset( f ); {-ga terug naar het begin van het bestand}
    for i:=1 to NrOfInitialLinesToScip do {-...en scip eerste regels}
      Readln( f, Regel );

    for i:=0 to NRows-1 do begin
//      SetLength( DynMatrix[ i ], NCols );
      {Write( lf, 'i,Matrix[1-NCols]: ', i+1:6, ' ' );}
      Readln( f, Regel );
      for j:=0 to NCols-1 do begin
        DynMatrix[ i ][ j ] := StrToFloat ( ExtractWord( j+1, Regel, WordDelims, Len ) );
        {Write( lf, FloatToStrF( DynMatrix[ i ][ j ], ffExponent, 8, 2 ), ' ' );}
      end;
      {Writeln( lf );}
    end;
    WriteToLogFile( 'All values read.' );

  Except
    raise Exception.Create( 'Initialisation failed in: ' +
                            '"TDoubleMatrix.InitialiseFromTextFile".' )
  end;
end;


Function TDoubleMatrix.SumOfColumn( const Col: Integer ): Double;
var i: Integer;
begin
  Result := 0;
  for i:=1 to GetNRows do
    Result := Result + GetValue( i, Col );
end;

Function TDoubleMatrix.MinOfColumn( const Col: Integer ): Double;
var
  n, i: Integer;
  aValue: Double;
begin
  n := GetNRows;
  if ( n > 0 ) then begin
    Result := GetValue( 1, Col );
    for i:=2 to n do begin
      aValue := GetValue( i, Col );
      if ( aValue < Result ) then
        Result := aValue;
    end;
  end else
    Result := 0;
end;

Function TDoubleMatrix.MaxOfColumn( const Col: Integer ): Double;
var
  n, i: Integer;
  aValue: Double;
begin
  n := GetNRows;
  if ( n > 0 ) then begin
    Result := GetValue( 1, Col );
    for i:=2 to n do begin
      aValue := GetValue( i, Col );
      if ( aValue > Result ) then
        Result := aValue;
    end;
  end else
    Result := 0;
end;

Function TDoubleMatrix.SumOfRow( const Row: Integer ): Double;
var i: Integer;
begin
  Result := 0;
  for i:=1 to GetNCols do
    Result := Result + GetValue( Row, i );
end;

Procedure TDoubleMatrix.WriteToTextFile( const aFileName: String; const ColSeparator: Char );
var
  f: TextFile;
begin
  AssignFile( f, aFileName ); Rewrite( f );
  WriteToTextFile( f, ColSeparator );
  CloseFile( f );
end;

Procedure TDoubleMatrix.WriteToTextFile( var f: TextFile; const ColSeparator: Char );
var
  i, j, NRows, NCols: Integer;
begin
  NRows := LowLevelGetNRows;
  NCols := LowLevelGetNCols;
  Writeln( f, NRows, ' ', NCols );
  for i:=1 to NRows do begin
    for j:=1 to NCols do
      Write( f, FloatToStrF( LowLevelGetValue( i, j ), ffExponent, 8, 2 ) + ColSeparator );
    Writeln( f );
  end;
end;

Procedure TDoubleMatrix.WriteDescendantTypeToTextFile( var f: TextFile );
begin
  Writeln( f, Ord( DescendantType ) );
end;

Function TDoubleMatrix.DescendantType: TDoubleArrayDescendant;
begin
  Result := cDoubleArray;
end;

Function TDoubleMatrix.Clone: TDoubleMatrix;
var
  NRows, NCols, Row: Integer;
begin
  {Application.MessageBox( 'TDoubleMatrix', 'Clone', MB_OK );}
  NRows  := LowLevelGetNRows;
  NCols  := LowLevelGetNCols;
  Result := TDoubleMatrix.Create( NRows, NCols, NIL );
  for Row:=0 to NRows-1 do
    Result.DynMatrix[ Row ] := Copy( DynMatrix[ Row ], 0, NCols );
end;

//Procedure TDoubleMatrix.DefineProperties(Filer: TFiler);
//begin
// inherited DefineProperties(Filer);
  { Define new properties and reader/writer methods }
//  Filer.DefineProperty('DoubleMatrixData', ReadAllData, WriteAllData, True );
//end;

procedure TDoubleMatrix.WriteAllData( Writer: TWriter );
var
  i, NRows, NCols: Integer;
begin
   Try
     NRows := GetNRows;
     NCols := GetNCols;
     Writer.WriteInteger( NRows );
     Writer.WriteInteger( NCols );
     for i := 0 to GetNRows-1 do begin
         Writer.Write( Pointer( DynMatrix[ i ] )^, NCols*SizeOf( Double ) );
     end;
  Except
    On E: Exception do
      Raise Exception.CreateFmt( 'Error in: ' +
        '"TDoubleMatrix.WriteAllData". NRows, NCols= %d, %d', [ GetNRows, GetNCols ] )
  End;
end;

procedure TDoubleMatrix.ReadAllData( Reader: TReader );
var
  NRows, NCols, i: Integer;
begin
  NRows := Reader.ReadInteger;
  NCols := Reader.ReadInteger;
  Try
    SetLength( DynMatrix, NRows  );
    for i:=0 to NRows-1 do begin
      SetLength( DynMatrix[ i ], NCols );
      Reader.Read( Pointer( DynMatrix[ i ] )^, NCols*SizeOf( Double ) );
    end;
  Except
    On E: Exception do
      Raise Exception.CreateFmt( 'Initialisation failed in: ' +
        '"TDoubleMatrix.ReadAllData". NRows, NCols= %d, %d', [ NRows, NCols ] )
  end;
end;

Function TDoubleMatrix.SaveToStream( SaveStream: TStream ): Boolean;
var
  NRows, NCols, i: Integer;
begin
  Result := true;
  Try
    NRows := GetNRows; NCols := GetNCols;
    SaveStream.Write( NRows, Sizeof( Integer ) );
    SaveStream.Write( NCols, Sizeof( Integer ) );
    for i := 0 to NRows-1 do begin
      SaveStream.WriteBuffer( Pointer( DynMatrix[ i ] )^, NCols*SizeOf( Double ) );
    end;
  Except
    Result := false
  End;
end;

Function TDoubleMatrix.LoadFromStream( LoadStream: TStream ): Boolean;
var
  NRows, NCols, i: Integer;
begin
  Result := true;
  Try
    LoadStream.Read( NRows, SizeOf( Integer ) );
    LoadStream.Read( NCols, SizeOf( Integer ) );
    SetLength( DynMatrix, NRows  );
    for i:=0 to NRows-1 do begin
      SetLength( DynMatrix[ i ], NCols );
      LoadStream.ReadBuffer( Pointer( DynMatrix[ i ] )^, NCols*SizeOf( Double ) );
    end;
  Except
    Result := false;
  end;
end;

Function TDbleMtrxColindx.GetColNr( const ColValue: Double ): Integer;
var
  j, nc: Integer;
  x: Double;
begin
  nc := GetNCols;
  j := 1;
  x := Inherited GetValue( 1, j );
  while ( ColValue > x ) and       {-Je moet verderop in de tabel zijn}
        ( j < nc ) do begin   {-Je bent nog niet bij de laatste waarde}
    Inc( j ); x := Inherited GetValue( 1, j );
  end;
  Result := j;
end;

Function TDbleMtrxColindx.DescendantType: TDoubleArrayDescendant;
begin
  Result := cDbleMtrxColindx;
end;

Function TDbleMtrxColindx.Clone: TDbleMtrxColindx;
var
  NRows, NCols, Row: Integer;
begin
  {Application.MessageBox( 'TDbleMtrxColindx', 'Clone', MB_OK );}
  NRows  := LowLevelGetNRows;
  NCols  := LowLevelGetNCols;
  Result := TDbleMtrxColindx.Create( NRows, NCols, NIL );
  for Row:=0 to NRows-1 do
    Result.DynMatrix[ Row ] := Copy( DynMatrix[ Row ], 0, NCols );
end;

Function TDbleMtrxColindx.GetValue( const Row: Integer; const ColValue:
                                    Double ): Double;
begin
  Result := Inherited GetValue( Row+1, GetColNr( ColValue ) );
end;

Function TDbleMtrxColindx.GetNRows: Integer;
begin
  GetNRows := Inherited GetNRows - 1;
end;

Procedure TDbleMtrxColindx.SetValue( const Row: Integer; const ColValue,
          Value: Double );
begin
  Inherited SetValue( Row+1, GetColNr( ColValue ), Value );
end;

Function TDbleMtrxColindx.SumOfColumn( const ColValue: Double ): Double;
var i, col, nr: Integer;
begin
  col := GetColNr( ColValue );
  nr := Inherited GetNRows;
  Result := 0;
  for i:=2 to nr do
    Result := Result + Inherited GetValue( i, Col );
end;

Function TDbleMtrxColindx.SumOfRow( const Row: Integer ): Double;
begin
  Result := Inherited SumOfRow( Row + 1 );
end;

Function TDbleMtrxColindx.GetValue( const Row: Integer; const ColValue,
         NoMatchValue: Double ): Double;
var
  j: integer;
  x: Double;
begin
  j := GetColNr( ColValue );
  x := Inherited GetValue( 1, j );
  if ( x = ColValue ) then
    Result := Inherited GetValue( Row+1, j )
  else
    Result := NoMatchValue;
end;

Procedure TDbleMtrxColindx.SetKeyValue( const Col: Integer; const Value: Double );
begin
  Inherited SetValue( 1, Col, Value );
end;

Function TDbleMtrxColAndRowIndx.GetColNr( const ColValue: Double ): Integer;
var
  j, nc: Integer;
  x: Double;
begin
  nc := inherited GetNCols;
  j := 2;
  x := Inherited GetValue( 1, j );
  while ( ColValue > x ) and       {-Je moet verderop in de tabel zijn}
        ( j < nc ) do begin   {-Je bent nog niet bij de laatste waarde}
    Inc( j ); x := Inherited GetValue( 1, j );
  end;
  Result := j;
end;

Function TDbleMtrxColAndRowIndx.DescendantType: TDoubleArrayDescendant;
begin
  Result := cDbleMtrxColAndRowIndx;
end;

Function TDbleMtrxColAndRowIndx.Clone: TDbleMtrxColAndRowIndx;
var
  NRows, NCols, Row: Integer;
begin
  NRows  := LowLevelGetNRows;
  NCols  := LowLevelGetNCols;  
  Result := TDbleMtrxColAndRowIndx.Create( NRows, NCols, NIL );
  for Row:=0 to NRows-1 do
    Result.DynMatrix[ Row ] := Copy( DynMatrix[ Row ], 0, NCols );
end;

Function TDbleMtrxColAndRowIndx.GetRowNr( const RowValue: Double ): Integer;
var
  j, nr: Integer;
  x: Double;
begin
  nr := inherited GetNRows;
  j := 2;
  x := Inherited GetValue( j, 1 );
  while ( RowValue > x ) and       {-Je moet verderop in de tabel zijn}
        ( j < nr ) do begin   {-Je bent nog niet bij de laatste waarde}
    Inc( j ); x := Inherited GetValue( j, 1 );
  end;
  Result := j;
end;

Function TDbleMtrxColAndRowIndx.GetUpColIndx( const ColValue: Double ): Integer;
var
  j, nc: Integer;
  x: Double;
begin
  nc := inherited GetNCols;
  j := 2;
  x := Inherited GetValue( 1, j );
  while ( ColValue >= x ) and       {-Je moet verderop in de tabel zijn}
        ( j < nc ) do begin   {-Je bent nog niet bij de laatste waarde}
    Inc( j ); x := Inherited GetValue( 1, j );
  end;
  Result := j;
end;

Function TDbleMtrxColAndRowIndx.GetUpRowIndx( const RowValue: Double ): Integer;
var
  j, nr: Integer;
  x: Double;
begin
  nr := inherited GetNRows;
  j := 2;
  x := Inherited GetValue( j, 1 );
  {$ifdef Test}
  Application.MessageBox( PChar(  'nr: ' + IntToStr( nr ) ), 'GetUpRowIndx', MB_OK );
  {$endif}
  while ( RowValue >= x ) and       {-Je moet verderop in de tabel zijn}
        ( j < nr ) do begin   {-Je bent nog niet bij de laatste waarde}
    Inc( j ); x := Inherited GetValue( j, 1 );
	{$ifdef Test}
	 Application.MessageBox( PChar(  'j, x: '
	    + IntToStr( j ) + ' ' +  FloatToStrF( x, ffExponent, 8, 4 ) ),
            'GetUpRowIndx', MB_OK );
	{$endif}
  end;
  Result := j;
end;

Function TDbleMtrxColAndRowIndx.GetValue( const RowValue, ColValue: Double ): Double;
begin
  Result := Inherited GetValue( GetRowNr( RowValue ), GetColNr( ColValue ) );
end;

Function TDbleMtrxColAndRowIndx.GetNRows: Integer;
begin
  Result := Inherited GetNRows - 1;
end;

Function TDbleMtrxColAndRowIndx.GetNCols: Integer;
begin
  Result := Inherited GetNCols - 1;
end;

Procedure TDbleMtrxColAndRowIndx.SetValue( const RowValue, ColValue,
          Value: Double );
begin
  Inherited SetValue( GetRowNr( RowValue ), GetColNr( ColValue ), Value );
end;

Function TDbleMtrxColAndRowIndx.SumOfColumn( const ColValue: Double ): Double;
var i, col, nr: Integer;
begin
  col := GetColNr( ColValue );
  nr := Inherited GetNRows;
  Result := 0;
  for i:=2 to nr do
    Result := Result + Inherited GetValue( i, Col );
end;

Function TDbleMtrxColAndRowIndx.SumOfRow( const RowValue: Double ): Double;
var i, Row, nc: Integer;
begin
  Row := GetRowNr( RowValue );
  nc := Inherited GetNCols;
  Result := 0;
  for i:=2 to nc do
    Result := Result + Inherited GetValue( Row, i );
end;

Function TDbleMtrxColAndRowIndx.GetValue( const RowValue, ColValue,
         NoMatchValue: Double ): Double;
var
  j, i: integer;
  cv, rv: Double;
begin
  j  := GetColNr( ColValue );
  cv := Inherited GetValue( 1, j );
  i  := GetRowNr( RowValue );
  rv := Inherited GetValue( i, 1 );
  if ( cv = ColValue ) and ( rv = RowValue ) then
    Result := Inherited GetValue( i, j )
  else
    Result := NoMatchValue;
end;

Procedure TDbleMtrxColAndRowIndx.SetColKeyValue( const Col: Integer; const Value: Double );
begin
  Inherited SetValue( 1, Col, Value );
end;

Procedure TDbleMtrxColAndRowIndx.SetRowKeyValue( const Row: Integer; const Value: Double );
begin
  Inherited SetValue( Row, 1, Value );
end;

Procedure TDbleMtrxColAndRowIndx.GetMinMaxIndexValues(
          var MinC, MaxC, MinR, MaxR: Double );
begin
  MinC := Inherited GetValue( 1, 2 );
  MaxC := Inherited GetValue( 1, inherited GetNCols );
  MinR := Inherited GetValue( 2, 1 );
  MaxR := Inherited GetValue( inherited GetNRows, 1 );
end;

Function TDbleMtrxColAndRowIndx.NoValue;
begin
  Result := Inherited GetValue( 1, 1 );
end;

Function TDbleMtrxColAndRowIndx.GetValueByLinearInterpolation( const RowValue,
         ColValue: Double ): Double;
var
  RowNr, ColNr, r1, r2, c1, c2: Integer;
  x1a, x1aJPLUS1, t, x2a, x2aJPLUS1, u, y1, y2, y3, y4,
  a1, a2, a3, a4, NoVal: Double;
begin
  RowNr := GetUpRowIndx( RowValue );
  ColNr := GetUpColIndx( ColValue );

  r2    := RowNr;
  r1    := Max( RowNr-1, 2 );
  c2    := ColNr;
  c1    := Max( ColNr-1, 2 );

  if ( c1 < c2 ) then begin
    x1a := Inherited GetValue( 1, c1 );
    x1aJPLUS1 := Inherited GetValue( 1, c2 );
    t := Max( Min( ( ColValue - x1a ) / ( x1aJPLUS1 - x1a ), 1 ), 0 );
  end else
    t := 0;

  if ( r1 < r2 ) then begin
    x2a := Inherited GetValue( r2, 1 );
    x2aJPLUS1 := Inherited GetValue( r1, 1 );
    u := Max( Min( ( RowValue - x2a ) / ( x2aJPLUS1 - x2a ), 1 ), 0 );
  end else
    u := 0;

  y1 := Inherited GetValue( r2, c1 );
  y2 := Inherited GetValue( r2, c2 );
  y3 := Inherited GetValue( r1, c2 );
  y4 := Inherited GetValue( r1, c1 );

  {$ifdef Test}
  Application.MessageBox( PChar(  'r1, r2, c1, c2: '
    + IntToStr( r1 ) + ' ' +  IntToStr( r2 )
    + ' ' +  IntToStr( c1 )+ ' ' +  IntToStr( c2 ) + #13 +
    't, u: ' + FloatToStrF( t, ffNumber, 1, 2 ) + ' ' +
     FloatToStrF( u, ffNumber, 1, 2 ) + #13 +
    'y1, y2, y3, y3: ' + FloatToStrF( y1, ffExponent, 8, 4 ) + ' ' +
                         FloatToStrF( y2, ffExponent, 8, 4 ) + ' ' +
                         FloatToStrF( y3, ffExponent, 8, 4 ) + ' ' +
                         FloatToStrF( y4, ffExponent, 8, 4 )
     ),
    'TDbleMtrxColAndRowIndx.GetMinMaxIndexValues', MB_OK );
  {$endif}

  NoVal := NoValue;
  
  a1 := (1-t)*(1-u);
  if ( y1 <> NoVal ) then
    a1 := a1 * y1
  else if ( ( y1 = NoVal ) and ( abs( a1 ) < MinSingle ) ) then
    a1 := 0
  else begin
    Result := NoVal; Exit;
  end;
  
  a2 := t*(1-u);
  if ( y2 <> NoVal ) then
    a2 := a2 * y2
  else if ( ( y2 = NoVal ) and ( abs( a2 ) < MinSingle ) ) then
    a2 := 0
  else begin
    Result := NoVal; Exit;
  end;

  a3 := t*u;
  if ( y3 <> NoVal ) then
    a3 := a3 * y3
  else if ( ( y3 = NoVal ) and ( abs( a3 ) < MinSingle ) ) then
    a3 := 0
  else begin
    Result := NoVal; Exit;
  end;

  a4 := (1-t)*u;
  if ( y4 <> NoVal ) then
    a4 := a4 * y4
  else if ( ( y4 = NoVal ) and ( abs( a4 ) < MinSingle ) ) then
    a4 := 0
  else begin
    Result := NoVal; Exit;
  end;

  Result := a1+a2+a3+a4;

end;

Function TDbleMtrxUngPar.GetUngParName( const RowValue: Integer ): String;
begin
  Result := Names[ RowValue-1 ];
end;

Procedure TDbleMtrxUngPar.SetUngParName( const RowValue: Integer; const aName: String );
begin
  Names[ Rowvalue-1 ] := aName;
end;

Procedure TDbleMtrxUngPar.WriteToAviewTextFile( var f: TextFile );
var
  i, n: Integer;
begin
  n := GetNRows;
  Writeln( f, '"ID","Name","X","Y","Z"' );
  for i:=1 to n do begin
    Writeln( f, Format('%d', [GetID( i )] ) + ','
    + '"' + GetUngParName( i ) + '",'
    + Format('%.2f', [Getx( i ) ] ) + ','
    + Format('%.2f', [Gety( i ) ] ) + ','
    + Format('%.2f', [Getz( i ) ] ) );
  end;
end;

Constructor TDbleMtrxUngPar.InitialiseFromTextFile( const FileName: String;
  AOwner: TComponent );
var
  FullPathNameOfUngFile, FullPathNameOfParFile, Line, FullPathNameOfNamFile: String;
  f, g, h: TextFile;
  n, ID, i: LongInt;
  x, y, Value: Double;
  ReadNamInfo: Boolean;
  Function GetZFromParFile( const ID: LongInt ): Double;
  var
    anID: LongInt;
    aValue: Double;
  begin
    Result := noValue;
    Try
      Reset( g );
      Repeat
        Readln( g, anID, aValue );
        if ( anID = ID ) then
          Result := aValue;
      Until ( ( Result <> noValue ) or EOF( g ) );
    Except
    end;
  end;
  Function GetNamFromNamFile( const ID: LongInt ): String;
  var
    anID: LongInt;
    aName: String;
  begin
    Result := '';
    Try
      Reset( h );
      Repeat
        Readln( h, anID, aName );
        aName := Trim( aName );
        if ( anID = ID ) then
          Result := aName;
      Until ( ( Result <> '' ) or EOF( h ) );
    Except
    end;
  end;
begin
  Try
    Try
      FullPathNameOfUngFile := ExpandFileName( ChangeFileExt( FileName,'.ung' ) );
      WriteToLogFile( 'Initialise TDoubleMatrix.InitialiseFromUngAndParFile (or descendant). Filename: "' + FullPathNameOfUngFile + '".' );
      {$I-}
      AssignFile( f, FullPathNameOfUngFile ); Reset( f );
      {$I+}
      if IOResult <> 0 then
        Raise EErrorOpeningUngParFile.CreateResFmt( @sCouldNotOpenUngParFile, [FullPathNameOfUngFile]  );

      FullPathNameOfParFile := ExpandFileName( ChangeFileExt( FileName,'.par' ) );
      {$I-}
      AssignFile( g, FullPathNameOfParFile ); Reset( g );
      {$I+}
      if IOResult <> 0 then
        Raise EErrorOpeningUngParFile.CreateResFmt( @sCouldNotOpenUngParFile, [FullPathNameOfParFile]  );

      {-Count nr. of point values (id, x, y, value)}
      n := 0;
      Repeat
        Readln( f, Line ); Trim( Line );
        if ( Line <> 'END' ) then
          Inc( n );
      Until ( EOF( f ) or ( Line = 'END' ) );

      if ( n = 0 ) then
        Raise EUngParFileContainsNoPointValues.CreateResFmt( @sUngParFileContainsNoPointValues, [FullPathNameOfParFile]  );

      WriteToLogFileFmt( 'Trying to read %d points.', [n] );

      Reset( f );
      Inherited CreateF( n, 4, NoValue, AOwner );

      Names := TStringList.Create;
      for i:=1 to n do
        Names.Append( '' );

      FullPathNameOfNamFile := ExpandFileName( ChangeFileExt( FileName,'.nam' ) );
      ReadNamInfo := FileExists( FullPathNameOfNamFile );
      if ReadNamInfo then begin
        WriteToLogFileFmt( 'Name file will be read [%s].', [FullPathNameOfNamFile] );
        AssignFile( h,  FullPathNameOfNamFile ); Reset( h );
      end;

      for i:=1 to n do begin
        Try
          Readln( f, ID, x, y ); {Writeln( lf, '* ', ID, ' ', x, ' ', y );}
          Value := GetZFromParFile( ID );
          SetValue( i, 1, ID );
          SetValue( i, 2, x );
          SetValue( i, 3, y );
          SetValue( i, 4, Value );  {Writeln( lf, '** ',ID, ' ', x, ' ', y, ' ', Value );}
          if ReadNamInfo then
            SetUngParName( i, GetNamFromNamFile( ID ) );
          WriteToLogFileFmt( 'ID=%d, x=%g, y=%g, Value=,%g, Name=%s.', [ID, x, y, Value, GetUngParName( i )] );
        except
          Raise EErrorReadingPointsFromUngParFile.Create( 'Error reading point ' + IntToStr( i ) + ' in TDbleMtrxUngPar' );
        end;
      end;

      WriteToLogFileFmt( 'TDbleMtrxUngPar initialised with %d elements', [n] );
    Finally
      {I-} CloseFile( f ); CloseFile( g ); {CloseFile( h );}{I+}
    end;
  Except
    On E: EErrorReadingPointsFromUngParFile do begin
      HandleError( Format( sErrorReadingPointsFromUngParFile, [FullPathNameOfUngFile] ), true );
    end;
    On E: Exception do begin
      HandleError( E.Message, true );
    end;
  end;
end;

Function TDbleMtrxUngPar.NoValue: Double;
begin
  Result := -999;
end;

Function TDbleMtrxUngPar.GetID( const RowValue: Integer ): Integer;
begin
  Result := Trunc( GetValue( RowValue, 1 ) );
end;

Function TDbleMtrxUngPar.Getx( const RowValue: Integer ): Double;
begin
  Result := GetValue( RowValue, 2 );
end;

Function TDbleMtrxUngPar.Gety( const RowValue: Integer ): Double;
begin
  Result := GetValue( RowValue, 3 );
end;

Function TDbleMtrxUngPar.Getz( const RowValue: Integer ): Double;
begin
  Result := GetValue( RowValue, 4 );
end;

Procedure TDbleMtrxUngPar.SetID( const RowValue: Integer; const Value: Integer );
begin
  SetValue( RowValue, 1, Value );
end;

Procedure TDbleMtrxUngPar.Setx( const RowValue: Integer; const Value: Double );
begin
  SetValue( RowValue, 2, Value );
end;

Procedure TDbleMtrxUngPar.Sety( const RowValue: Integer; const Value: Double );
begin
  SetValue( RowValue, 3, Value );
end;

Procedure TDbleMtrxUngPar.Setz( const RowValue: Integer; const Value: Double );
begin
  SetValue( RowValue, 4, Value );
end;

Function TDbleMtrxUngPar.DescendantType: TDoubleArrayDescendant;
begin
  Result := cUngPar;
end;

Function TDbleMtrxUngPar.Clone: TDbleMtrxUngPar;
var
  i, NRows, NCols, Row: Integer;
begin
  {Application.MessageBox( 'TDoubleMatrix', 'Clone', MB_OK );}
  NRows  := LowLevelGetNRows;
  NCols  := LowLevelGetNCols;
  Result := TDbleMtrxUngPar.Create( NRows, NCols, NIL );
  Names := TStringList.Create;
  for i:=1 to NRows do
    Names.Append( '' );
  for Row:=0 to NRows-1 do begin
    Result.DynMatrix[ Row ] := Copy( DynMatrix[ Row ], 0, NCols );
    Result.Names[ Row ] := Names[ Row ];
  end;
end;

procedure Register;
begin
  RegisterComponents('MyComponents', [TLargeRealArray, TLargeIntegerArray,
  TDoubleMatrix, TDbleMtrxColindx, TDbleMtrxColAndRowIndx, TDbleMtrxUngPar]);
end;

begin
 with FormatSettings do begin {-Delphi XE6}
  Decimalseparator := '.';
 end;
end.

