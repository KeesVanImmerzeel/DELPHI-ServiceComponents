{: Contains the Registrations for the components in
 ESB Professional Computation Suite.

 This is designed to work in Delphi 4 and above.

 Copyright © 1999-2002 ESB Consultancy<p>

 v2.3 - 14 September 2002
}
unit ESBPCSRegFree;

{$I esbpcs.inc}

interface

procedure Register;

implementation

uses
     Classes,
     {$IFDEF BelowD6}
     DsgnIntf,
     {$ELSE}
     {DesignIntf, DesignEditors,}
     {$ENDIF}
     { Globals}
     ESBPCSGlobals, ESBPCSGlobals2,
     { Edits }
     ESBPCSEdit, ESBPCSNumEdit;

procedure Register;
begin
     RegisterComponents ('ESBPCS', [TESBPCSEdit, TESBPosEdit, TESBIntEdit,
          TESBPosFloatEdit, TESBFloatEdit, TESBSciFloatEdit, TESBPercentEdit,
               TESBIPEdit, TESBHexEdit]);

end;

end.
