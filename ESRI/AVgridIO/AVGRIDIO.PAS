unit AVGRIDIO; {-Grid IO API }

interface
uses
  Windows, sysutils, Vcl.Forms, Vcl.Dialogs, uESRI, uError;

{-Constants Defining String Handling }

const
  MaxStrLen = 129; {/* Max string Length*/}
  cTRUE = 1;           {-Defined C constants }
  cFALSE = 0;
  cNULL = 0;
  cREADONLY = 1;       {-Constants Defining CellLayer ReadWrite Flag }
  cREADWRITE = 2;
  cWRITEONLY = 3;
  cROWIO = 1;     {-Constants Defining CellLayer I/O Mode }
  cCELLIO = 2;    {-Buffer Cache Allocation is dependent on IO mode. }
  cBLOCKIO = 3;
  cROWRUNIO = 4;
  cBLOCKRUNIO = 5;
  cREGIONIO = 6;
  cREGIONRUNIO = 7;
  cCELLINT = 1; {/* 32 bit signed integers*/}
  cCELLFLOAT = 2; {/* 32 bit floating point numbers*/}
  cCELLMAX = 2147483646; {/* maximum integer value (2**31 - 2)*/}
  cCELLMIN = -2147483646; {/* minimum integer value -(2**31 - 2)*/}
  MISSINGINT = -2147483647; {/* CELLMIN - 1*/}

Type
  TCELLTYPE = Integer;  {= cell values are 32 bit quantities }
  PTCELLTYPE = ^TCELLTYPE;

  EErrorInitiating_IO_Library_for_ESRI_GRID_raster_datasets = class( Exception );
Resourcestring
  sErrorInitiating_IO_Library_for_ESRI_GRID_raster_datasets = 'Error initiating IO library for ESRI GRID raster datasets.';

var
  GetMissingFloat: procedure(_1: PSingle) cdecl;
  MissingSingle: Single;

  Function InitialiseGridIO: Integer; {ROEP DEZE FUNCTIE AAN VOORDAT AVGRIDIO-ROUTINES WORDEN GEBRUIKT!!!}

{-* Grid Management Functions }
var
  {-* GridExists - check for existence of a grid }
  GridExists: function(grid_name: PANSIChar): Integer cdecl;
  {-* GridCopy - copy a grid given from and to pathnames }
  GridCopy: function(from_grid: PANSIChar; to_grid: PANSIChar): Integer cdecl;
  {-* GridRename - rename a grid given old and new pathnames }
  GridRename: function(from_grid: PANSIChar; to_grid: PANSIChar): Integer cdecl;
  {-* GridDelete - delete a grid removing all component files including info files }
  GridDelete: function(grid_name: PANSIChar): Integer cdecl;
  {-* GridKill - delete a grid with options for component removal }
  GridKill: function(grid_name: PANSIChar; option: Integer): Integer cdecl;
  {-* DescribeGridDbl - Describe spatial, statistical and attribute characteristics of a grid}
  DescribeGridDbl: function(grdnam: PANSIChar;
                            var cellsz: Double;
                            var gridsz: Integer;
                            var box: Double; 
                            var sta: Double;
                            var datatyp: Integer;
                            var nclass: Integer;
                            var reclen: Integer): Integer cdecl;
  {-* BndCellRead - read the bounding box for a grid }
  BndCellRead: function(grdnam: PANSIChar; var box: TbndBox ): Integer cdecl;

{-* CLYRIO : Access operations on Grids }
{-* PURPOSE }
{-* CLYRIO performs I/O operations on grids. }
{-* It consists of a library of C functions that allow the user }
{-* to read and write raster data by row, rectangle or cell }
{-* to or from a specified area of a grid at a specified resolution. }
{-* It handles windowing, resampling, }
{-* attribute access and data compression }
{-* in a manner transparent to the application program. }
{= }

{+// }
{-* IMPLEMENTATION }
{-* }
{-* Grids are based on a locational data model in which space is partitioned }
{-* into square cells. Each cell in a grid stores a numeric value. }
{-* Integer Grids are also accompanied by Value Attribute Tables that }
{-* can store attributes defined on the set of values for a grid. }
{-* }
{-* A grid exists in a cartesian coordinate system, and the rows and columns in the }
{-* grid are parallel to the axes of the coordinate system. }
{-* Grids in a database that are used for joint analysis }
{-* need not be at the same resolution }
{-* or cover exactly the same spatial area }
{-* but they must be in the same map projection. }
{-* }
{-* Grids are implemented using a tiled raster data structure }
{-* in which the basic unit of data storage is }
{-* a rectangular block of cells. }
{-* }
{-* A Cell Layer is a raster layer defined }
{-* by a grid name and optionally an item name in the VAT. }
{-* The CLYRIO module allows an aplication program to }
{-* create, open and close cell layers and }
{-* to read and write data from and }
{-* to cell layers. }
{-* All access to the data in a cell layer is }
{-* made through a rectangular window in cartesian (map) coordinate space. }
{-* The extent and resolution of }
{-* this window must be set by the application program by calling }
{-* the WindowSet routine, prior to performing any }
{-* I/O operations. }
{-* Once a window has been set, an application program can access the cells }
{-* in a cell layer by row, rectangle, or cell - all specified }
{-* relative to the virtual raster represented by the window. }
{-* }
{-* The I/O units used by the application program are }
{-* the Window-Row spanning the width of the window, the Window-Band consisting }
{-* of a set of contiguos rows, the Window-Rectangle consisting of a 2D rectangle }
{-* contained in the window and, the Window-Cell consisting of a single cell }
{-* specified by its window row and column coordinates. }
{-* All cell data is automatically resampled to the window cell size on retrieval }
{-* during row and cell access. }
{-* }
{-* An application program can either set a global window }
{-* that is applied to all cell layers accessed or set a separate }
{-* window for each layer accessed. The latter mode is suitable }
{-* when transforming a grid from one coordinate system to another }
{-* such as during warping or projection. }
{-* }
{-* Grids may be integer or floating point. }
{-* Integer grids are accompanied by a Value Attribute Table. }
{-* The CLYRIO module supports spatial access to the numeric value }
{-* attributes associated with a grid by supporting }
{-* a grid.item naming convention for cell layers that correspond }
{-* to grid value attributes. }
{-* If an item name is specified when a Cell Layer is opened }
{-* for read access then the values returned for the cells retrieved }
{-* will be the values for the specified item. }
{-* }
{= }


{+// }
{-* Initialization and Termination }
{-* -------------------------------- }
{-* }
{-* GridIOSetup - Initialize the Grid IO library }
{-* GridIOExit - Call when done using the Grid IO library }
{= }
var
  GridIOSetup: function: Integer cdecl;
var
  GridIOExit: function: Integer cdecl;


{+// }
{-* Creating, Opening and Closing Grids : }
{-* ----------------------------------- }
{-* }
{-* CellLyrExists - Check if a cell layer exists. }
{-* CellLayerCreate - Create a new Cell Layer using the default blocksize. }
{-* CellLayerCreateTiled - Create a new Cell Layer using the specified blocksize. }
{-* CellLayerOpen - Open an existing Cell Layer. }
{-* CellLyrClose - Close an opened or created Cell Layer, }
{-* automatically builds VAT and STA. }
{-* CellLyrCloseNoVat - Close an opened or created Cell Layer, }
{-* does not build VAT. }
{-* CellLyrDelete - Delete a cell layer. }
{-* }
{-* IO mode }
{-* ------- }
{-* }
{-* The client is responsible for selecting an IO mode }
{-* when opening or creating a cell layer and for using }
{-* the access method appropriate for the current IO mode. }
{-* The IO mode can be reset while the layer is opened. }
{-* The permissible values for IO mode are }
{-* ROWIO, ROWRUNIO, CELLIO, REGIONIO, REGIONRUNIO, BLOCKIO and BLOCKRUNIO }
{-* For a more detailed description of these modes see the }
{-* section on IO mode below. }
{-* }
{-* ReadWriteFlag }
{-* ------------- }
{-* A celllayer is opened READONLY or READWRITE }
{-* }
{-* Compression }
{-* ----------- }
{-* }
{-* Integer grids are stored in a run length compressed format. }
{-* Floating point grids are stored in uncompressed format. }
{-* }
{= }



const
  ADAPTIVE = -1;

const
  COMPRESSED = 0;
const
  UNCOMPRESSED = 1;

var
  CellLyrExists: function(clyr_name: PANSIChar): Integer cdecl;

var
  CellLayerCreate: function(clyr_name: PANSIChar;
                            rdwrflag: Integer; 
                            iomode: Integer; 
                            celltype: Integer;
                            cellsize: Double;
                            var box: TBndBox): Integer cdecl;

var
  CellLayerCreateTiled: function(clyr_name: PANSIChar;
                                 rdwrflag: Integer;
                                 iomode: Integer;
                                 celltype: Integer;
                                 cellsize: Double;
                                 var box: TBndBox;
                                 blockxcells: Integer;
                                 blockycells: Integer): Integer cdecl; 

var
  CellLayerOpen: function(clyr_name: PANSIChar;
                          rdwrflag: Integer; 
                          iomode: Integer; 
                          var celltype: Integer; 
                          var cellsize: Double): Integer cdecl; 

var
  CellLyrClose: function(channel: Integer): Integer cdecl;
var
  CellLyrCloseNoVat: function(channel: Integer): Integer cdecl;
var
  CellLyrDelete: function(clyr_name: PANSIChar): Integer cdecl;

{+// }
{-* AcessDepth }
{-* }
{-* CLYRIO mantains an internal cache of block buffers for each opened grid. }
{-* }
{-* The process of performing IO on a cell layer involves }
{-* mapping data between client buffers and cache buffers }
{-* for the layer and between the cache buffers and records on disk. }
{-* Data compression is applied in the process of mapping data between the }
{-* cache buffers and records on disk and is hidden from the client. }
{-* }
{-* When a layer is opened in 32 bit mode the client is responsible }
{-* for ensuring that all client (input and output) buffers used in the }
{-* CLYRIO API functions are 32 bits per cell. }
{-* In 32 bit access mode all the block buffers in the cache for the layer }
{-* are also 32 bits per cell. }
{-* The Client is responsible for using the 32 bit API functions. }
{-* By default a layer is opened in 32 bit mode. }
{-* }
{-* }
{= }



{+// }
{-* IO mode }
{-* }
{-* The client is responsible for using }
{-* the access method appropriate for the current IO mode. }
{-* The IO modes supported are : }
{-* }
{-* ROWIO - To Get and Put Rows of Cells }
{-* CELLIO - To Get and Put individual cells }
{-* REGIONIO - To Get and Put Rectangles of cells }
{-* }
{-* The IO mode for an opened layer can be queried and changed }
{-* with the following API calls }
{-* }
{= }
var
  CellLyrGetIO: function(channel: Integer): Integer cdecl;
var
  CellLyrSetIO: function(channel: Integer; 
                         mode: Integer): Integer cdecl; 


{+// }
{-* Getting information about an opened cell layer given its handle }
{-* }
{-* CellLyrName - query the grid name for the cell layer }
{-* CellLyrItem - query the item name for the cell layer }
{-* CellLyrEvalType - query the cell type for the cell layer, }
{-* the cell type is based on the type of the item }
{-* CellLyrBlockSize - query the block size for the cell layer }
{-* CellLyrSta - query the statistics for the cell layer }
{= }

var
  CellLyrName: function(channel: Integer; 
                        name: PANSIChar): Integer cdecl;
var
  CellLyrItem: function(channel: Integer; 
                        name: PANSIChar): Integer cdecl;
var
  CellLyrEvalType: function(channel: Integer): Integer cdecl; 
var
  CellLyrBlockSize: function(channel: Integer;
                             var bxcells: Integer; 
                             var bycells: Integer): Integer cdecl; 
var
  CellLyrSta: function(channel: Integer; 
                       var dmin: Double; 
                       var dmax: Double;
                       var dmean: Double; 
                       var dstdv: Double): Integer cdecl; 


{+// }
{-* Setting and Querying the Overlay Window for Multi-Layer registered I/O }
{-* }
{-* AccessWindowSet - Set the Overlay Window }
{-* WindowRows - Return number of rows in the overlay window. }
{-* WindowCols - Return number of columns in the overlay window. }
{-* WindowBox - Return the box for the overlay window. }
{-* XY2WindowColRow - translate from map to window cell coordinates }
{-* AccessWindowClear - Clear the Overlay Window }
{= }

var
  AccessWindowSet: function(var box: TBndBox; 
                            cellsize: Double; 
                            var newbox: TBndBox): Integer cdecl;
var
  WindowRows: function: Integer cdecl; 
var
  WindowCols: function: Integer cdecl;
var
  WindowBox: function(var box: TBndBox): Integer cdecl;
var
  XY2WindowColRow: function(x: Double; 
                            y: Double; 
                            var col: Integer; 
                            var row: Integer): Integer cdecl; 
var
  AccessWindowClear: function: Integer cdecl; 

{+// }
{-* }
{-* Routines for Setting Separate Windows for each layer }
{-* }
{-* PrivateAccessWindowSet - Set the Window for the specified layer. }
{-* PrivateWindowRows - Return number of rows in window for specified layer. }
{-* PrivateWindowColumns - Return number of columns in window for specified layer. }
{-* PrivateWindowBox - Return the box for the window for specified layer. }
{-* XY2PrivateWindowColRow - translate from map to window cell coordinates }
{-* PrivateAccessWindowClear - Clear the window for the specified layer }
{= }

var
  PrivateAccessWindowSet: function(channel: Integer; 
                                   var box: TBndBox; 
                                   cellsize: Double; 
                                   var newbox: TBndBox): Integer cdecl;
var
  PrivateWindowCols: function(i: Integer): Integer cdecl;
var
  PrivateWindowRows: function(i: Integer): Integer cdecl; 
var
  PrivateWindowBox: function(i: Integer; 
                             var box: TBndBox): Integer cdecl;
var
  XY2PrivateWindowColRow: function(i: Integer;
                                   x: Double; 
                                   y: Double; 
                                   var col: Integer;
                                   var row: Integer): Integer cdecl; 
var
  PrivateAccessWindowClear: function(channel: Integer): Integer cdecl;


{+// }
{-* Memory Allocation for Rows, Bands and Rectangles }
{-* }
{-* CAllocate1 - allocate a 1 dimensional array (Row) }
{-* that can be accessed as pointer[i] }
{-* CAllocate2 - allocate a 2 dimensional "array" (Rectangle, Band) }
{-* that can be accessed as pointer[i][j] }
{-* CAllocate3 - allocate a 3 dimensional "array" }
{-* that can be accessed as pointer[i][j][k] }
{-* CFree1 - free a 1 dimensional array }
{-* CFree2 - free a 2 dimensional array }
{-* CFree3 - free a 3 dimensional array }
{-* }
{= }

var
  CAllocate1: function(number: Integer;
                       size: Integer): PANSIChar cdecl;
var
  CAllocate2: function(nrows: Integer; 
                       ncols: Integer;
                       size: Integer): PANSIChar cdecl;
var
  CAllocate3: function(nlyrs: Integer;
                       nrows: Integer;
                       ncols: Integer; 
                       size: Integer): PANSIChar cdecl;

var
  CFree1: procedure(ptr: PANSIChar) cdecl;
var
  CFree2: procedure(var ptr: PANSIChar;
                    nrows: Integer) cdecl; 
var
  CFree3: procedure(var ptr: PANSIChar;
                    nlyrs: Integer;
                    nrows: Integer) cdecl;

{+// }
{-* ACCESS FUNCTIONS : }
{-* The following functions access the data within the window for a given layer. }
{-* The window may be the overlay window, or the private window set for the layer. }
{= }

{+// }
{-* Routines for 32 bit ROW based access : }
{-* }
{-* GetWindowRow - Get a row spanning the window for a layer }
{-* as a buffer of 32 bit values. }
{-* Client must interpret the type of the output buffer }
{-* to be the type of the layer being read from (32 bit int or float). }
{-* }
{-* GetWindowRowFloat - Get a row as a buffer of 32 bit floating points }
{-* GetWindowRowInt - Get a row as a buffer of 32 bit integers }
{-* }
{-* PutWindowRow - Put a row spanning the window for a layer }
{-* as a buffer of 32 bit values. }
{-* Client must ensure that the type of the input buffer }
{-* (32 bit int or float) is the type of the layer being written to. }
{-* }
{-* The following band access functions retrieve contiguos sets of }
{-* rows into a two dimensional buffer. }
{-* }
{-* GetWindowBand - Get a band of rows spanning the window for a layer. }
{-* Client must interpret the type of the output buffer }
{-* to be the type of the layer being read from (32 bit int or float). }
{-* GetWindowBandFloat - Get a band of rows as a buffer of 32 bit floating points }
{-* GetWindowBandInt - Get a band of rows as a buffer of 32 bit ints }
{-* }
{-* PutWindowBand - Put a band of rows spanning the window for a layer. }
{-* Client must ensure that the type of the input buffer }
{-* (32 bit int or float) is the type of the layer being written to. }
{-* }
{= }


var
  GetWindowRow: function(channel: Integer; 
                         nreswinrow: Integer; 
                         var rowbuf: TCELLTYPE): Integer cdecl;
var
  GetWindowRowFloat: function(channel: Integer; 
                              nreswinrow: Integer; 
                              var rowbuf: Single): Integer cdecl; 
var
  GetWindowRowInt: function(channel: Integer; 
                            nreswinrow: Integer; 
                            var rowbuf: Integer): Integer cdecl; 

var
  PutWindowRow: function(channel: Integer; 
                         nwinrow: Integer; 
                         var rowbuf: TCELLTYPE): Integer cdecl;

var
  GetWindowBand: function(channel: Integer;
                          startrow: Integer; 
                          nrows: Integer; 
                          var bandbuf): Integer cdecl;
var
  GetWindowBandFloat: function(channel: Integer;
                               startrow: Integer;
                               nrows: Integer; 
                               var bandbuf: Double): Integer cdecl;
var
  GetWindowBandInt: function(channel: Integer; 
                             startrow: Integer; 
                             nrows: Integer; 
                             var bandbuf: Integer): Integer cdecl;

var
  PutWindowBand: function(channel: Integer; 
                          startrow: Integer;
                          nrows: Integer; 
                          var bandbuf): Integer cdecl;




{+// }
{-* Routines for 32 bit REGION (rectangle) based access : }
{-* }
{-* GetWindowRectangle - Get a rectangle of cells within the window for a layer }
{-* as a 2D buffer of 32 bit values. }
{-* Client must interpret the type of the output buffer }
{-* to be the type of the layer being read from }
{-* (32 bit int or float). }
{-* }
{-* GetWindowRectangleInt - Get a rectangle of cells within the window for a layer }
{-* as a 2D buffer of 32 bit integers. }
{-* }
{-* GetWindowRectangleFloat - Get a rectangle of cells within the window for a layer }
{-* as a 2D buffer of 32 bit floats. }
{-* }
{-* PutWindowRectangle - Put a rectangle of cells within the window for a layer }
{-* as a 2D buffer of 32 bit values. }
{-* Client must ensure that the type of the input buffer }
{-* (32 bit int or float) is the type of the }
{-* layer being written to. }
{= }

var
  GetWindowRectangle: function(channel: Integer; 
                               rxul: Integer; 
                               ryul: Integer;
                               rxcells: Integer; 
                               rycells: Integer; 
                               var rbuf): Integer cdecl;
var
  GetWindowRectangleInt: function(channel: Integer; 
                                  rxul: Integer;
                                  ryul: Integer;
                                  rxcells: Integer; 
                                  rycells: Integer;
                                  var rbuf: Integer): Integer cdecl;
var
  GetWindowRectangleFloat: function(channel: Integer; 
                                    rxul: Integer;
                                    ryul: Integer;
                                    rxcells: Integer; 
                                    rycells: Integer; 
                                    var rbuf: Double): Integer cdecl;

var
  PutWindowRectangle: function(channel: Integer; 
                               rxul: Integer; 
                               ryul: Integer;
                               rxcells: Integer;
                               rycells: Integer; 
                               var rbuf): Integer cdecl; 


{+// }
{-* Routines for 32 bit CELL based access : }
{-* }
{-* GetWindowCell - Get a cell within the window for a layer, }
{-* Client must interpret the type of the output 32 Bit Ptr }
{-* to be the type of the layer being read from. }
{-* }
{-* GetWindowCellFloat - Get a cell within the window for a layer as a 32 Bit Float }
{-* }
{-* GetWindowCellInt - Get a cell within the window for a layer as a 32 Bit Integer }
{-* }
{-* PutWindowCell - Put a cell within the window for a layer. }
{-* Client must ensure that the type of the input 32 Bit Ptr }
{-* is the type of the layer being read from. }
{-* }
{-* }
{-* PutWindowCellFloat - Put a cell within the window for a layer as a 32 Bit Float }
{-* }
{-* PutWindowCellInt - Put a cell within the window for a layer as a 32 Bit Integer }
{-* }
{= }
var
  GetWindowCell: function(channel: Integer; 
                          rescol: Integer; 
                          resrow: Integer; 
                          var cell: TCELLTYPE): Integer cdecl;
var
  GetWindowCellFloat: function(channel: Integer;
                               rescol: Integer; 
                               resrow: Integer; 
                               var cell: Single): Integer cdecl;
var
  GetWindowCellInt: function(channel: Integer; 
                             rescol: Integer;
                             resrow: Integer; 
                             var cell: Integer): Integer cdecl; 

var
  PutWindowCellFloat: function(channel: Integer;
                               col: Integer; 
                               row: Integer; 
                               fcell: Single ): Integer cdecl;
var
  PutWindowCellInt: function(channel: Integer;
                             col: Integer;
                             row: Integer; 
                             icell: Integer): Integer cdecl;
var
  PutWindowCell: function(channel: Integer;
                          col: Integer;
                          row: Integer; 
                          cell: TCELLTYPE): Integer cdecl;


{-* STAIO : Read Statistics for a cell layer }
{-* StaGetDbl - get min, max, mean and stdv for a cell layer }
{-* StaGetMinMaxDbl - get min and max for a cell layer }

var
  StaGetDbl: function(clyr_name: PANSIChar;
                      var dmin: Double; 
                      var dmax: Double; 
                      var dmean: Double; 
                      var dstdv: Double): Integer cdecl; 

var
  StaGetMinmaxDbl: function(clyr_name: PANSIChar;
                            var dmin: Double; 
                            var dmax: Double): Integer cdecl;



var
  DLLLoaded: Boolean { is DLL (dynamically) loaded already? }
    {$IFDEF WIN32} = False; {$ENDIF}

implementation

var
  SaveExit: pointer;
  DLLHandle, DLLHandle2: THandle;
{$IFNDEF MSDOS}
  ErrorMode: Integer;
{$ENDIF}

  procedure NewExit; far;
  begin
    ExitProc := SaveExit;
    FreeLibrary(DLLHandle) ; FreeLibrary(DLLHandle2)

  end {NewExit};

procedure LoadDLL;
begin
  if DLLLoaded then Exit;
{$IFNDEF MSDOS}
  ErrorMode := SetErrorMode($8000{SEM_NoOpenFileErrorBox});
{$ENDIF}
  DLLHandle := LoadLibrary('AVGRIDIO.DLL');
  if DLLHandle >= 32 then

  begin
    DLLHandle2 := LoadLibrary('avbase.DLL');
    DLLLoaded := True;
    SaveExit := ExitProc;
    ExitProc := @NewExit;
    @GetMissingFloat := GetProcAddress(DLLHandle,'GetMissingFloat');
  {$IFDEF WIN32}
    Assert(@GetMissingFloat <> nil);
  {$ENDIF}
    @GridExists := GetProcAddress(DLLHandle,'GridExists');
  {$IFDEF WIN32}
    Assert(@GridExists <> nil);
  {$ENDIF}
    @GridCopy := GetProcAddress(DLLHandle,'GridCopy');
  {$IFDEF WIN32}
    Assert(@GridCopy <> nil);
  {$ENDIF}
    @GridRename := GetProcAddress(DLLHandle,'GridRename');
  {$IFDEF WIN32}
    Assert(@GridRename <> nil);
  {$ENDIF}
    @GridDelete := GetProcAddress(DLLHandle,'GridDelete');
  {$IFDEF WIN32}
    Assert(@GridDelete <> nil);
  {$ENDIF}
    @GridKill := GetProcAddress(DLLHandle,'GridKill');
  {$IFDEF WIN32}
    Assert(@GridKill <> nil);
  {$ENDIF}
    @DescribeGridDbl := GetProcAddress(DLLHandle,'DescribeGridDbl');
  {$IFDEF WIN32}
    Assert(@DescribeGridDbl <> nil);
  {$ENDIF}
    @BndCellRead := GetProcAddress(DLLHandle,'BndCellRead');
  {$IFDEF WIN32}
    Assert(@BndCellRead <> nil);
  {$ENDIF}
    @GridIOSetup := GetProcAddress(DLLHandle,'GridIOSetup');
  {$IFDEF WIN32}
    Assert(@GridIOSetup <> nil);
  {$ENDIF}
    @GridIOExit := GetProcAddress(DLLHandle,'GridIOExit');
  {$IFDEF WIN32}
    Assert(@GridIOExit <> nil);
  {$ENDIF}
    {ShowMessage( 'Loading function CellLyrExists' );}
    @CellLyrExists := GetProcAddress(DLLHandle,'CellLyrExists');
    {ShowMessage( 'Function CellLyrExists loaded' );}
  {$IFDEF WIN32}
    Assert(@CellLyrExists <> nil);
  {$ENDIF}
    @CellLayerCreate := GetProcAddress(DLLHandle,'CellLayerCreate');
  {$IFDEF WIN32}
    Assert(@CellLayerCreate <> nil);
  {$ENDIF}
    @CellLayerCreateTiled := GetProcAddress(DLLHandle,'CellLayerCreateTiled');
  {$IFDEF WIN32}
    Assert(@CellLayerCreateTiled <> nil);
  {$ENDIF}
    @CellLayerOpen := GetProcAddress(DLLHandle,'CellLayerOpen');
  {$IFDEF WIN32}
    Assert(@CellLayerOpen <> nil);
  {$ENDIF}
    @CellLyrClose := GetProcAddress(DLLHandle,'CellLyrClose');
  {$IFDEF WIN32}
    Assert(@CellLyrClose <> nil);
  {$ENDIF}
    @CellLyrCloseNoVat := GetProcAddress(DLLHandle,'CellLyrCloseNoVat');
  {$IFDEF WIN32}
    Assert(@CellLyrCloseNoVat <> nil);
  {$ENDIF}
    @CellLyrDelete := GetProcAddress(DLLHandle,'CellLyrDelete');
  {$IFDEF WIN32}
    Assert(@CellLyrDelete <> nil);
  {$ENDIF}
    @CellLyrGetIO := GetProcAddress(DLLHandle,'CellLyrGetIO');
  {$IFDEF WIN32}
    Assert(@CellLyrGetIO <> nil);
  {$ENDIF}
    @CellLyrSetIO := GetProcAddress(DLLHandle,'CellLyrSetIO');
  {$IFDEF WIN32}
    Assert(@CellLyrSetIO <> nil);
  {$ENDIF}
    @CellLyrName := GetProcAddress(DLLHandle,'CellLyrName');
  {$IFDEF WIN32}
    Assert(@CellLyrName <> nil);
  {$ENDIF}
    @CellLyrItem := GetProcAddress(DLLHandle,'CellLyrItem');
  {$IFDEF WIN32}
    Assert(@CellLyrItem <> nil);
  {$ENDIF}
    @CellLyrEvalType := GetProcAddress(DLLHandle,'CellLyrEvalType');
  {$IFDEF WIN32}
    Assert(@CellLyrEvalType <> nil);
  {$ENDIF}
    @CellLyrBlockSize := GetProcAddress(DLLHandle,'CellLyrBlockSize');
  {$IFDEF WIN32}
    Assert(@CellLyrBlockSize <> nil);
  {$ENDIF}
    @CellLyrSta := GetProcAddress(DLLHandle,'CellLyrSta');
  {$IFDEF WIN32}
    Assert(@CellLyrSta <> nil);
  {$ENDIF}
    @AccessWindowSet := GetProcAddress(DLLHandle,'AccessWindowSet');
  {$IFDEF WIN32}
    Assert(@AccessWindowSet <> nil);
  {$ENDIF}
    @WindowRows := GetProcAddress(DLLHandle,'WindowRows');
  {$IFDEF WIN32}
    Assert(@WindowRows <> nil);
  {$ENDIF}
    @WindowCols := GetProcAddress(DLLHandle,'WindowCols');
  {$IFDEF WIN32}
    Assert(@WindowCols <> nil);
  {$ENDIF}
    @WindowBox := GetProcAddress(DLLHandle,'WindowBox');
  {$IFDEF WIN32}
    Assert(@WindowBox <> nil);
  {$ENDIF}
    @XY2WindowColRow := GetProcAddress(DLLHandle,'XY2WindowColRow');
  {$IFDEF WIN32}
    Assert(@XY2WindowColRow <> nil);
  {$ENDIF}
    @AccessWindowClear := GetProcAddress(DLLHandle,'AccessWindowClear');
  {$IFDEF WIN32}
    Assert(@AccessWindowClear <> nil);
  {$ENDIF}
    @PrivateAccessWindowSet := GetProcAddress(DLLHandle,'PrivateAccessWindowSet');
  {$IFDEF WIN32}
    Assert(@PrivateAccessWindowSet <> nil);
  {$ENDIF}
    @PrivateWindowCols := GetProcAddress(DLLHandle,'PrivateWindowCols');
  {$IFDEF WIN32}
    Assert(@PrivateWindowCols <> nil);
  {$ENDIF}
    @PrivateWindowRows := GetProcAddress(DLLHandle,'PrivateWindowRows');
  {$IFDEF WIN32}
    Assert(@PrivateWindowRows <> nil);
  {$ENDIF}
    @PrivateWindowBox := GetProcAddress(DLLHandle,'PrivateWindowBox');
  {$IFDEF WIN32}
    Assert(@PrivateWindowBox <> nil);
  {$ENDIF}
    @XY2PrivateWindowColRow := GetProcAddress(DLLHandle,'XY2PrivateWindowColRow');
  {$IFDEF WIN32}
    Assert(@XY2PrivateWindowColRow <> nil);
  {$ENDIF}
    @PrivateAccessWindowClear := GetProcAddress(DLLHandle,'PrivateAccessWindowClear');
  {$IFDEF WIN32}
    Assert(@PrivateAccessWindowClear <> nil);
  {$ENDIF}
    @CAllocate1 := GetProcAddress(DLLHandle2,'CAllocate1');
  {$IFDEF WIN32}
    Assert(@CAllocate1 <> nil);
  {$ENDIF}
    @CAllocate2 := GetProcAddress(DLLHandle2,'CAllocate2');
  {$IFDEF WIN32}
    Assert(@CAllocate2 <> nil);
  {$ENDIF}
    @CAllocate3 := GetProcAddress(DLLHandle2,'CAllocate3');
  {$IFDEF WIN32}
    Assert(@CAllocate3 <> nil);
  {$ENDIF}
    @CFree1 := GetProcAddress(DLLHandle2,'CFree1');
  {$IFDEF WIN32}
    Assert(@CFree1 <> nil);
  {$ENDIF}
    @CFree2 := GetProcAddress(DLLHandle2,'CFree2');
  {$IFDEF WIN32}
    Assert(@CFree2 <> nil);
  {$ENDIF}
    @CFree3 := GetProcAddress(DLLHandle2,'CFree3');
  {$IFDEF WIN32}
    Assert(@CFree3 <> nil);
  {$ENDIF}
    @GetWindowRow := GetProcAddress(DLLHandle,'GetWindowRow');
  {$IFDEF WIN32}
    Assert(@GetWindowRow <> nil);
  {$ENDIF}
    @GetWindowRowFloat := GetProcAddress(DLLHandle,'GetWindowRowFloat');
  {$IFDEF WIN32}
    Assert(@GetWindowRowFloat <> nil);
  {$ENDIF}
    @GetWindowRowInt := GetProcAddress(DLLHandle,'GetWindowRowInt');
  {$IFDEF WIN32}
    Assert(@GetWindowRowInt <> nil);
  {$ENDIF}
    @PutWindowRow := GetProcAddress(DLLHandle,'PutWindowRow');
  {$IFDEF WIN32}
    Assert(@PutWindowRow <> nil);
  {$ENDIF}
    @GetWindowBand := GetProcAddress(DLLHandle,'GetWindowBand');
  {$IFDEF WIN32}
    Assert(@GetWindowBand <> nil);
  {$ENDIF}
    @GetWindowBandFloat := GetProcAddress(DLLHandle,'GetWindowBandFloat');
  {$IFDEF WIN32}
    Assert(@GetWindowBandFloat <> nil);
  {$ENDIF}
    @GetWindowBandInt := GetProcAddress(DLLHandle,'GetWindowBandInt');
  {$IFDEF WIN32}
    Assert(@GetWindowBandInt <> nil);
  {$ENDIF}
    @PutWindowBand := GetProcAddress(DLLHandle,'PutWindowBand');
  {$IFDEF WIN32}
    Assert(@PutWindowBand <> nil);
  {$ENDIF}
    @GetWindowRectangle := GetProcAddress(DLLHandle,'GetWindowRectangle');
  {$IFDEF WIN32}
    Assert(@GetWindowRectangle <> nil);
  {$ENDIF}
    @GetWindowRectangleInt := GetProcAddress(DLLHandle,'GetWindowRectangleInt');
  {$IFDEF WIN32}
    Assert(@GetWindowRectangleInt <> nil);
  {$ENDIF}
    @GetWindowRectangleFloat := GetProcAddress(DLLHandle,'GetWindowRectangleFloat');
  {$IFDEF WIN32}
    Assert(@GetWindowRectangleFloat <> nil);
  {$ENDIF}
    @PutWindowRectangle := GetProcAddress(DLLHandle,'PutWindowRectangle');
  {$IFDEF WIN32}
    Assert(@PutWindowRectangle <> nil);
  {$ENDIF}
    @GetWindowCell := GetProcAddress(DLLHandle,'GetWindowCell');
  {$IFDEF WIN32}
    Assert(@GetWindowCell <> nil);
  {$ENDIF}
    @GetWindowCellFloat := GetProcAddress(DLLHandle,'GetWindowCellFloat');
  {$IFDEF WIN32}
    Assert(@GetWindowCellFloat <> nil);
  {$ENDIF}
    @GetWindowCellInt := GetProcAddress(DLLHandle,'GetWindowCellInt');
  {$IFDEF WIN32}
    Assert(@GetWindowCellInt <> nil);
  {$ENDIF}
    @PutWindowCellFloat := GetProcAddress(DLLHandle,'PutWindowCellFloat');
  {$IFDEF WIN32}
    Assert(@PutWindowCellFloat <> nil);
  {$ENDIF}
    @PutWindowCellInt := GetProcAddress(DLLHandle,'PutWindowCellInt');
  {$IFDEF WIN32}
    Assert(@PutWindowCellInt <> nil);
  {$ENDIF}
    @PutWindowCell := GetProcAddress(DLLHandle,'PutWindowCell');
  {$IFDEF WIN32}
    Assert(@PutWindowCell <> nil);
  {$ENDIF}
    @StaGetDbl := GetProcAddress(DLLHandle,'StaGetDbl');
  {$IFDEF WIN32}
    Assert(@StaGetDbl <> nil);
  {$ENDIF}
    @StaGetMinmaxDbl := GetProcAddress(DLLHandle,'StaGetMinmaxDbl');
  {$IFDEF WIN32}
    Assert(@StaGetMinmaxDbl <> nil);
  {$ENDIF}
  end
  else
  begin
    DLLLoaded := False;
    { Error: AVGRIDIO.DLL could not be loaded !! }
  end;
{$IFNDEF MSDOS}
  SetErrorMode(ErrorMode)
{$ENDIF}
end {LoadDLL};

Function InitialiseGridIO: Integer;
begin
  Result := cUnknownError;
  Try
    Try
      if GridIOSetup < 0 then
        Raise Exception.CreateRes( @sErrorInitiating_IO_Library_for_ESRI_GRID_raster_datasets );
      GetMissingFloat( @MissingSingle );
      WriteToLogFile( 'Missing Single after GridIOSetup= ' + FloatToStr( MissingSingle ) );
      Result := cNoError;
    Except
      On E: Exception do begin
        MessageDlg( E.Message, mtError, [mbOk], 0); Application.terminate;
      end;
    end;
  Finally
    Try
      GridIOExit;
    Except
    end;
  end;
end;

begin
  LoadDLL;
  {MissingSingle := -3.40282346638529E+0038;}
end.
