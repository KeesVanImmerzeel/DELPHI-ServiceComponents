unit Uipf;

interface

uses
  SysUtils, Classes;

type
  TipfRecord = Record
    x, y: Single;
    LabelStr: String;
  end;
  Tipf = class( Tcomponent )
  private
    { Private declarations }
    iID: String;
    ipfData: Array of TipfRecord;
    Function GetValue( const i: Integer ): Single; Virtual;
  protected
    { Protected declarations }
  public
    { Public declarations }
    Constructor InitFromIPFfile( const FileName: TFileName; var iResult: Integer );
    Destructor Destroy;  override;
    Function WriteToArcViewTable( const FileName: TFileName ): Integer; Virtual;
    Function Count: Integer; Virtual;
    Function GetID: String; Virtual;
    Function IsValueDataSet: Boolean; Virtual;
    Procedure GetXY( const i: Integer; var x, y: Double ); Virtual;
    Function GetLabel( const i: Integer ): String; Virtual;
  published
    { Published declarations }
  end;

Const
  noIPFvalue = -99999999;

procedure Register;

implementation

uses
  Math, OpWString, uError;

Constructor Tipf.InitFromIPFfile( const FileName: TFileName; var iResult: Integer );
var
  i, n, nCols: Integer;
  f: TextFile;
  s: String;
  {x,y: Single; }
begin
  iResult := -1;
  Try
    Try
      WriteToLogFileFmt( 'Tipf.InitFromIPFfile [%s].', [ExpandFileName( FileName )] );
      iID := ExtractFileName( FileName );
      i := Pos( '.', iID );
      iID := copy( iID, 0, i-1 );
      WriteToLogFileFmt( 'iID: [%d].', [iID] );
      AssignFile( f, FileName ); Reset( f);
      Readln( f, n );
      WriteToLogFileFmt( 'Nr. of elements: [%d].', [n] );
      SetLength( ipfData, n );
      Readln( f, nCols );
      WriteToLogFileFmt( 'Nr. of columns: [%d].', [nCols] );

      For i:=1 to nCols+1 do begin
        Readln( f, s );
        {WriteToLogFileFmt( s );}
      end;
      for i:=0 to n-1 do begin
        with ipfData[ i ] do begin
          Readln( f, x, y, LabelStr ); LabelStr := Trim( LabelStr );
          {WriteToLogFileFmt( i, ' ', x:10:2, ',', y:10:2, ',"' + LabelStr + '"' );}
        end;
      end;
      if IsValueDataSet then
        WriteToLogFile( 'IsValueDataSet.' )
      else
        WriteToLogFile( 'IsStringDataSet.' );
    Except
    end;
    iResult := 0;
  Finally
    CloseFile( f );
  end; {-Try}
end;

Function Tipf.GetLabel( const i: Integer ): String;
begin
  Result :=  ipfData[ i-1 ].LabelStr;
end;

Procedure Tipf.GetXY( const i: Integer; var x, y: Double );
begin
  if ( i > 0 ) and ( i <= count ) then begin
    x := ipfData[ i-1 ].x;
    y := ipfData[ i-1 ].y;
  end else begin
    x := noIPFvalue;
    y := noIPFvalue;
  end;
end;


Destructor Tipf.Destroy;
begin
  SetLength( ipfData, 0 );
  Inherited Destroy;
end;

Function Tipf.GetID: String;
begin
  Result := iID;
end;

Function Tipf.WriteToArcViewTable( const FileName: TFileName ): Integer;
var
  i: Integer;
  f: TextFile;
  WriteNumbers: Boolean;
begin
  Try
    Try
      AssignFile( f, FileName ); Rewrite( f);
      Writeln( f, '"X","Y","' + GetID + '"' );
      WriteNumbers := IsValueDataSet;
      for i:=0 to Count-1 do begin
        with ipfData[ i ] do begin
          if not WriteNumbers then
            Writeln( f, x:9:2, ',', y:9:2, ',"' + LabelStr + '"' )
          else
            Writeln( f, x:9:2, ',', y:9:2, ', ', GetValue( i ) );
        end;
      end;
    Except
      Result := -1;
    end;
    Result := 0;
  Finally
    CloseFile( f );
  end; {-Try}
end;

Function Tipf.Count: Integer;
begin
  Count := Length( ipfData );
end;

Function Tipf.GetValue( const i: Integer ): Single;
var
  Code: Integer;
begin
  {$R-}
  Val( ipfData[ i ].LabelStr, Result, Code );
  {R+}
  if Code <> 0 then
    Result := noIPFvalue;
end;

Function Tipf.IsValueDataSet: Boolean;
var
  Code: Integer;
  aNumber: Single;
begin
  {$R-}
  Val( ipfData[ 0 ].LabelStr, aNumber, Code );
  {R+}
  Result := ( Code = 0 );
end;

procedure Register;
begin
  RegisterComponents('MyComponents', [Tipf]);
end;

begin
  with FormatSettings do begin {-Delphi XE6}
    Decimalseparator := '.';
  end;
end.
