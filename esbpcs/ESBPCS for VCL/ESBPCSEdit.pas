{: Contains the General Edit Components for ESB Professional
 Computation Suite.

 This is designed to work in Delphi 4 and above.<p>

 This suite of Edit Components is aimed at making Data Entry easier
 by supporting Alignment, Read Only Colouring, On Focus Colouring,
 Handling of Enter as Tab, Handling of Arrow Keys as Tabs, only numeric
 characters in numeric fields, formatting options dependent upon Data
 Type, Methods to aid in manipulation of Data Types.<p>

 Plus many of the Edit Components are used in various Compound
 Components within ESBPCS.<p>

 For Date/Time Edit Components see <See Unit=ESBPCSDateTimeEdit>.
 For Currency Edit Components see <See Unit=ESBPCSCurrencyEdit>.
 For Numeric Edit Components see <See Unit=ESBPCSNumEdit>.<p>

 Copyright © 1999-2002 ESB Consultancy<p>

 v2.3 - 14 September 2002
}

unit ESBPCSEdit;

{$I esbpcs.inc}

interface

uses
     Classes, Controls, Graphics, StdCtrls, Messages,
     ESBPCSGlobals, ESBPCSGlobals2;

type
     {: Enhanced Custom Edit Control with Alignment and Enhanced Color Changing.
      ColorRW replaces the normal Color Property of Standard Edit Controls.<p>
      By default Read Only fields will be shown in a different Color,
      to disable this set ColorRW and ColorRO to the same, eg clWindow.
      clBtnFace is often a better choice for ColorRO on older Video Cards
      and older Notebooks<p>
      ColorFocus can be used so that the Color of the edit field changes
      when it receives focus (provided it is not ReadOnly). To use this feature
      ColorFocus must be set to a different value than ColorRW but beware
      the various Color combinations that result.<p>
      ColorDisabled controls the Color of the Control when Disabled, ie
      Enabled := False.<p>
      Flat controls whether the control has a MS Office 97/2000 type behaviour,
      where the "look" changes when the control has focus or the mouse passes
      over it. ColorBorderFocus & ColorBorderUnfocus are used for Border colors
      when the Control is Flat.<p>
      OnMouseEnter & OnMouseExit - allow you to set up your own "hot" controls
      if the Flat look'n'feel is not what you are after.<p>
      Null allows an edit field to be marked as having no proper value,
      and it will then display whatever NullStr is set to. Ctrl-N is
      the Keyboard entry for Null if AllowKbdNull is true. OnNullEvent
      is called when the Keyboard entry of Null is permitted.<p>
      If <See Var=ESBEnterAsTab> is true then the Enter Key will be treated
      as though it were the Tab Key.<p>
      If <See Var=ESBEscAsUndo> is true then the Esc Key will be cause an Undo
      to occur in the field.<p>
      If Arrows is False and <See Var=ESBArrowsAsTab> is true then Up Arrow will move to previous
      field like Shift-Tab, and Down Arrow will move to next field like
      Tab. }
     TESBCustomEdit = class (TCustomEdit)
     private
          { Private declarations }
          fAlignment: TAlignment; // Edit Field Alignment
          fAllowKbdNull: Boolean; // When True Ctrl-N gives Keyboard Null and OnNull Event called
          fBlankWhenNull: Boolean; // Should Nulls be displayed as Blanks
          fColorFocus: TColor; // Color to use when the field is Focused
          fColorRO: TColor; // Color to use when the field is ReadOnly
          fColorRW: TColor; // Color to use when the field is Read/Write
          fColorBorderFocus: TColor; // Color to use for Border when control is Flat and has Focus
          fColorBorderUnfocus: TColor; // Color to use for Border when control is Flat and does not have Focus
          fColorDisabled: TColor; // Color to display Control in when disabled
          fFocused: Boolean; // Set to True when control has the focus
          fNull: Boolean; // Set to True when the cell contains a Null Value
          fNullStr: string; // Value to display when fNull is True
          fReadOnly: Boolean; // New ReadOnly Property
          fMouseOver: Boolean; // Set to True when Mouse is over the control
          fColor_Defaults: Boolean;
          fFlatBorder: Integer;
          fFlat: Boolean; // True when control is to be handled as a Flat control
          fStrValue: string; // String Value - replacement for Text
          fInUpdate: Boolean; // In Updating Mode
          fStoreValue: Boolean; // Controls whether the current value is stored
          fLineEdit: Boolean;
          fNumPadDecimal: Boolean;

          fOnEnter: TNotifyEvent; // Replacement Enter Routine
          fOnExit: TNotifyEvent; // Replacement Exit Routine
          fOnKeyPress: TKeyPressEvent; // Replacement OnKeyPressRoutine
          fOnNull: TNotifyEvent; // Event Called when Null is Set
          fOnCNKeyDown: TKeyEvent; // Event called when Control Notification of key Down
          fOnMouseEnter: TNotifyEvent; // Called when Mouse enters the Controls's Area
          fOnMouseExit: TNotifyEvent; // Called when Mouse leaves the Controls's Area
     protected
          fValidChar: TESBCharSet; // Set of Valid Characters for Keyboard Input
          fValidCharHold: TESBCharSet; // Held Valid Char
          fNumPadPressed: Boolean;
          fNoDisplayUpdate: Boolean;
          fBlankIsNull: Boolean;

          procedure CreateParams (var Params: TCreateParams); override;
          procedure CMEnabledChanged (var Msg: TMessage); message CM_ENABLEDCHANGED;
          procedure CMMouseEnter (var Msg: TMessage); message CM_MOUSEENTER;
          procedure CMMouseLeave (var Msg: TMessage); message CM_MOUSELEAVE;
          procedure CMFontChanged (var Msg: TMessage); message CM_FONTCHANGED;
          procedure CNKeyDown (var Msg: TWMKeyDown); message CN_KEYDOWN;
          procedure WMNCPaint (var Msg: TMessage); message WM_NCPAINT;
          procedure WMPaste (var Msg: TMessage); message WM_PASTE;
          procedure WMCut (var Msg: TMessage); message WM_CUT;

          procedure KeyPress (var Key: Char); override;
          procedure KeyProcess (var Key: Char);
          procedure KeyDown (var Key: Word; Shift: TShiftState); override;
          procedure DoEnter; override;
          procedure DoExit; override;
          procedure MouseUp (Button: TMouseButton; Shift: TShiftState;
               X, Y: Integer); override;

          procedure SetAlignment (Value: TAlignment);
          procedure SetBlankWhenNull (Value: Boolean);
          procedure SetColorFocus (Value: TColor);
          procedure SetColorDisabled (Value: TColor);
          procedure SetColorBorderFocus (Value: TColor);
          procedure SetColorBorderUnfocus (Value: TColor);
          procedure SetColorRO (Value: TColor);
          procedure SetColorRW (Value: TColor);
          procedure SetFlat (Value: Boolean);
          procedure SetLineEdit (Value: Boolean);
          procedure SetFlatBorder (Value: Integer);
          procedure SetNull (Value: Boolean);
          procedure SetNullStr (const Value: string);
          procedure SetReadOnly (Value: Boolean);
          function GetVersion: string;
          procedure SetVersion (const Value: string);
          function GetStrValue: string; virtual;
          procedure SetStrValue (const Value: string); virtual;
          procedure Convert2Value; virtual;
          procedure SetColor_Defaults (Value: Boolean);

          procedure DisplayText; virtual;
          procedure UpdateColors;
          procedure FlattenControl;

          function StoreNullStr: Boolean;
          procedure SetColors2Defaults; virtual;

     public
          { Public declarations }
          //: Creates the Edit Component.
          constructor Create (AOwner: TComponent); override;

          //: Causes all Colour Updates to Wait until the EndUpdate is called
          procedure BeginUpdate;

          //: Causes all Colour Updates to wait from when BeginUpdate is called
          procedure EndUpdate;
          //: Causes the Selection to be Removed
          procedure SelectNone;
          //: Returns True if the field is Clear
          function IsClear: Boolean;

          //: function to indicate whether value is stored in form
          function ValueStored: Boolean;

     published
          { Published declarations }

          {: Boolean Flag to signify if the control should be store the design
           time value, or simply use the value it defaults to when created. }
          property StoreValue: Boolean
               read fStoreValue
               write fStoreValue
               default True;
          {: When enabled, the NumPad Decimal Point will always be recognised
           as the Decimal Separator regardless of type of keyboard. }
          property NumPadDecimal: Boolean
               read fNumPadDecimal
               write fNumPadDecimal
               default False;
          {: Boolean Flag to signify if the control should be "Flat"
           like an MS Office 97/2000 Edit control. }
          property Flat: Boolean
               read fFlat
               write SetFlat
               default False;
          {: Boolean Flag to signify if the control should be a "line edit",
           this forces the control to also be Flat. }
          property LineEdit: Boolean
               read fLineEdit
               write SetLineEdit
               default False;
          {: Width of the Border of the Control when it is <See Property=Flat>.
           Can only be 1 or 2. }
          property FlatBorder: Integer
               read fFlatBorder
               write SetFlatBorder
               default DefBorderSize;
          {: When Set to True, Ctrl-N will set a field to Null
           and the OnNull event will be called. }
          property AllowKbdNull: Boolean
               read fAllowKbdNull
               write fAllowKbdNull
               default True;
          {: Boolean Flag to signify if the Value is Null - that is that
           no proper value is contained. Cell will display whateve
           NullStr is set to. }
          property Null: Boolean
               read fNull
               write SetNull
               default False;
          {: When Null is true, signifying that there is no proper value
           then this string is displayed. Can be Empty. }
          property NullStr: string
               read fNullStr
               write SetNullStr
               stored StoreNullStr;
          {: When enabled, the Edit Box will display "Empty" when the
           Value is Null. }
          property BlankWhenNull: Boolean
               read fBlankWhenNull
               write SetBlankWhenNull
               default False;

          {: Controls the Alignment of the displayed text in the Edit Fields
           accepted values are taLeftJustify, taRightJustify & taCenter. }
          property Alignment: TAlignment
               read fAlignment
               write SetAlignment
               default taLeftJustify;
          {: When Set to True all the Color Properties will get their current
           Default Values. Works similar to "ParentColor" }
          property Color_Defaults: Boolean
               read fColor_Defaults
               write SetColor_Defaults
               stored False
               default True;
          {: Color that Border of the Control is displayed in
           if the Control is focused and is Flat.
           If set to clNone then ColorBorderUnfocus will be used
           unless that is also clNone, then ColorRW will be used
           unless that is also clNone, then ParentColor will be used. }
          property ColorBorderFocus: TColor
               read fColorBorderFocus
               write SetColorBorderFocus
               default DefBorderFocusColor;
          {: Color that Border of the Control is displayed in
           if the Control is NOT focused and is Flat.
           If set to clNone then ColorBorderFocus will be used
           unless that is also clNone, then ColorRW will be used
           unless that is also clNone, then ParentColor will be used. }
          property ColorBorderUnfocus: TColor
               read fColorBorderUnfocus
               write SetColorBorderUnfocus
               default DefBorderNonFocusColor;
          {: Color that the Control is displayed in if the Control is
           Disabled, ie Enabled := False.
           If set to clNone then ColorRW will be used
           unless that is also clNone, then ParentColor will be used. }
          property ColorDisabled: TColor
               read fColorDisabled
               write SetColorDisabled
               default DefDisabledColor;
          {: Color that the Control is displayed in the Control is focused.
           If set to clNone then ColorRW will be used
           unless that is also clNone, then ParentColor will be used. }
          property ColorFocus: TColor
               read fColorFocus
               write SetColorFocus
               default DefFocusColor2;
          {: Color that the Control is displayed in if the Control is
           ReadOnly.
           If set to clNone then ColorRW will be used
           unless that is also clNone, then ParentColor will be used. }
          property ColorRO: TColor
               read fColorRO
               write SetColorRO
               default DefROColor;
          {: Color that the Control is displayed in if the Control is not
           ReadOnly, ie ReadWrite.
           If set to clNone then ParentColor will be used. }
          property ColorRW: TColor
               read fColorRW
               write SetColorRW
               default DefRWColor;
          {: Boolean Flag to signify if the Control is ReadOnly.
           <See Var=ESBNoTabStopOnReadOnly> controls if TabStop is also Toggled. }
          property ReadOnly: Boolean
               read fReadOnly
               write SetReadOnly
               default False;
          {: Overriden Text that still works the same way that
           the Standard TEdit property does, except it isn't stored. }
          property Text: string
               read GetStrValue
               write SetStrValue
               stored false;
          {: Alternate property to Text for completion . }
          property AsString: string
               read GetStrValue
               write SetStrValue
               stored false;
          {: Displays the Current Version of the Component. }
          property Version: string
               read GetVersion
               write SetVersion
               stored false;

          {: Overriden OnEnter that still works much the same way that
           the Standard TEdit Event does. }
          property OnEnter: TNotifyEvent
               read fOnEnter
               write fOnEnter;
          {: Overriden OnExit that still works much the same way that
           the Standard TEdit Event does. If Bounds Validation is Enabled,
           then it will be done before calling the inherited OnEnter. }
          property OnExit: TNotifyEvent
               read fOnExit
               write fOnExit;
          {: Overriden OnKeyPress that still works much the same way that
           the Standard TEdit Event does. }
          property OnKeyPress: TKeyPressEvent
               read fOnKeyPress
               write fOnKeyPress;
          {: This event is called if AllowKbdNull is true, and Ctrl-N is
           entered from the keyboard. }
          property OnNull: TNotifyEvent
               read fOnNull
               write fOnNull;
          {: Event called prior at the start of the Control Notification
           of key Down. This allows Tabs to be trapped. }
          property OnCNKeyDown: TKeyEvent
               read fOnCNKeyDown
               write fOnCNKeyDown;
          {: Event is called when the Mouse enters the Control's Area. }
          property OnMouseEnter: TNotifyEvent
               read fOnMouseEnter
               write fOnMouseEnter;
          {: Event is called when the Mouse leaves the Control's Area. }
          property OnMouseExit: TNotifyEvent
               read fOnMouseExit
               write fOnMouseExit;

          //: Published property from TCustomEdit
          property AutoSize;
          //: Published property from TCustomEdit
          property Font;
          //: Published property from TCustomEdit
          property ParentFont;
     end;

type
     {: Enhanced Edit Control with Alignment and ReadOnly Color Changing.
      Includes Methods to return the Text already Trimmed and in
      different cases.<p>
      ColorRW replaces the normal Color Property of Standard Edit Controls.<p>
      By default Read Only fields will be shown in a different Color,
      to disable this set ColorRW and ColorRO to the same, eg clWindow.
      clBtnFace is often a better choice for ColorRO on older Video Cards
      and older Notebooks<p>
      ColorFocus can be used so that the Color of the edit field changes
      when it receives focus (provided it is not ReadOnly). To use this feature
      ColorFocus must be set to a different value than ColorRW but beware
      the various Color combinations that result.<p>
      ColorDisabled controls the Color of the Control when Disabled, ie
      Enabled := False.<p>
      Flat controls whether the control has a MS Office 97/2000 type behaviour,
      where the "look" changes when the control has focus or the mouse passes
      over it. ColorBorderFocus & ColorBorderUnfocus are used for Border colors
      when the Control is Flat.<p>
      OnMouseEnter & OnMouseExit - allow you to set up your own "hot" controls
      if the Flat look'n'feel is not what you are after.<p>
      Null allows an edit field to be marked as having no proper value,
      and it will then display whatever NullStr is set to. Ctrl-N is
      the Keyboard entry for Null if AllowKbdNull is true. OnNullEvent
      is called when the Keyboard entry of Null is permitted.<p>
      If <See Var=ESBEnterAsTab> is true then the Enter Key will be treated
      as though it were the Tab Key.<p>
      If <See Var=ESBEscAsUndo> is true then the Esc Key will be cause an Undo
      to occur in the field.<p>
      If Arrows is False and <See Var=ESBArrowsAsTab> is true then Up Arrow will move to previous
      field like Shift-Tab, and Down Arrow will move to next field like
      Tab. }
     TESBPCSEdit = class (TESBCustomEdit)
     private
          fProperAdjust: Boolean;
          fTrimTrailing: Boolean;
          fTrimLeading: Boolean;
          fAutoAdvance: Boolean;
     protected
          procedure DoExit; override;
          procedure KeyUp (var Key: Word; Shift: TShiftState); override;
     public
          //: Creates the Edit Component.
          constructor Create (AOwner: TComponent); override;

          //: Returns the Text in Lower Case using AnsiLowerCase. Result is also Trimmed.
          function LowerText: string;
          {: Returns the Text in Proper Case using <See Routine=ESBProperStr>.
           Result is also Trimmed.}
          function ProperText: string;
          //: Returns the Text trimmed of leading and trailing spaces.
          function TrimmedText: string;
          //: Returns the Text in Upper Case using AnsiUpperCase. Result is also Trimmed
          function UpperText: string;
     published
          {: When True and MaxLength > 0 then when the last character is
           entered the focus moves to the next control. }
          property AutoAdvance: Boolean
               read fAutoAdvance
               write fAutoAdvance
               default False;
          {: At Runtime, if on Exiting the Field and the Field is not ReadOnly
           and has Value of '' then it will be set to Null if this property
           is true. Similarly if the field is set to ''. }
          property BlankIsNull: Boolean
               read fBlankIsNull
               write fBlankIsNull
               default False;
          {: When True Trims trailing spaces when the control is exited. }
          property TrimTrailing: Boolean
               read fTrimTrailing
               write fTrimTrailing
               default True;
          {: When True Trims leading spaces when the control is exited. }
          property TrimLeading: Boolean
               read fTrimLeading
               write fTrimLeading
               default False;
          {: When True converts text into Proper Case when the control
           is exited. Uses <See Routine=ESBProperStr>. }
          property ProperAdjust: Boolean
               read fProperAdjust
               write fProperAdjust
               default False;
          {: Overriden Text that still works the same way that
           the Standard TEdit property does. }
          property Text
               stored ValueStored;

          //: Published property from TCustomEdit
          property Align;
          //: Published property from TCustomEdit
          property Anchors;
          //: Published property from TCustomEdit
          property AutoSelect;
          //: Published property from TCustomEdit
          property BiDiMode;
          //: Published property from TCustomEdit
          property BorderStyle;
          //: Published property from TCustomEdit
          property CharCase;
          //property Color;
          //: Published property from TCustomEdit
          property Constraints;
          //: Published property from TCustomEdit
          property Ctl3D;
          //: Published property from TCustomEdit
          property DragCursor;
          //: Published property from TCustomEdit
          property DragKind;
          //: Published property from TCustomEdit
          property DragMode;
          //: Published property from TCustomEdit
          property Enabled;
          //: Published property from TCustomEdit
          property HideSelection;
          //: Published property from TCustomEdit
          property ImeMode;
          //: Published property from TCustomEdit
          property ImeName;
          //: Published property from TCustomEdit
          property MaxLength;
          //: Published property from TCustomEdit
          property OEMConvert;
          //: Published property from TCustomEdit
          property ParentBiDiMode;
          //property ParentColor;
          //: Published property from TCustomEdit
          property ParentCtl3D;
          //: Published property from TCustomEdit
          property ParentShowHint;
          //: Published property from TCustomEdit
          property PasswordChar;
          //: Published property from TCustomEdit
          property PopupMenu;
          //property ReadOnly;
                  //: Published property from TCustomEdit
          property ShowHint;
          //: Published property from TCustomEdit
          property TabOrder;
          //: Published property from TCustomEdit
          property TabStop;
          //: Published property from TCustomEdit
          property Visible;
          //: Published property from TCustomEdit
          property OnClick;
          {$IFNDEF BelowD5}
          //: Published property from TCustomEdit
          property OnContextPopup;
          {$ENDIF}
          //: Published property from TCustomEdit
          property OnChange;
          //: Published property from TCustomEdit
          property OnDblClick;
          //: Published property from TCustomEdit
          property OnDragDrop;
          //: Published property from TCustomEdit
          property OnDragOver;
          //: Published property from TCustomEdit
          property OnEndDock;
          //: Published property from TCustomEdit
          property OnEndDrag;
          //: Published property from TCustomEdit
          property OnKeyDown;
          //: Published property from TCustomEdit
          property OnKeyUp;
          //: Published property from TCustomEdit
          property OnMouseDown;
          //: Published property from TCustomEdit
          property OnMouseMove;
          //: Published property from TCustomEdit
          property OnMouseUp;
          //: Published property from TCustomEdit
          property OnMouseWheel;
          //: Published property from TCustomEdit
          property OnMouseWheelDown;
          //: Published property from TCustomEdit
          property OnMouseWheelUp;
          //: Published property from TCustomEdit
          property OnStartDock;
          //: Published property from TCustomEdit
          property OnStartDrag;
     end;

     {: Enhanced Base Edit Control that forms the basis for the various
      Type Specific Edit Controls. This Component is not actually
      used itself but as the Parent of the other controls. <p>
      This adds Replacement Methods and framework for Bounds Validation.<p>
      Edit Control has Alignment and ReadOnly Color Changing.
      Includes Methods to return the Text already Trimmed and in
      different cases.<p>
      Flat controls whether the control has a MS Office 97/2000 type behaviour,
      where the "look" changes when the control has focus or the mouse passes
      over it. ColorBorderFocus & ColorBorderUnfocus are used for Border colors
      when the Control is Flat.<p>
      OnMouseEnter & OnMouseExit - allow you to set up your own "hot" controls
      if the Flat look'n'feel is not what you are after.<p>
      Null allows an edit field to be marked as having no proper value,
      and it will then display whatever NullStr is set to. Ctrl-N is
      the Keyboard entry for Null if AllowKbdNull is true. OnNullEvent
      is called when the Keyboard entry of Null is permitted.<p>
      ColorRW replaces the normal Color Property of Standard Edit Controls.<p>
      By default Read Only fields will be shown in a different Color,
      to disable this set ColorRW and ColorRO to the same, eg clWindow.
      clBtnFace is often a better choice for ColorRO on older Video Cards
      and older Notebooks<p>
      ColorFocus can be used so that the Color of the edit field changes
      when it receives focus (provided it is not ReadOnly). To use this feature
      ColorFocus must be set to a different value than ColorRW but beware
      the various Color combinations that result.<p>
      ColorDisabled controls the Color of the Control when Disabled, ie
      Enabled := False.<p>
      If <See Var=ESBEnterAsTab> is true then the Enter Key will be treated
      as though it were the Tab Key.<p>
      If <See Var=ESBEscAsUndo> is true then the Esc Key will be cause an Undo
      to occur in the field.<p>
      If Arrows is False and <See Var=ESBArrowsAsTab> is true then Up Arrow will move to previous
      field like Shift-Tab, and Down Arrow will move to next field like
      Tab. }
     TESBBaseEdit = class (TESBCustomEdit)
     private
          fMaxLength: Integer; // Replacement MaxLength for Zero padding

          fOnBoundsError: TESBBoundsValidationEvent; // User defined Routine when Bounds Validation problem occurs
          fOnExitStart: TESBExitStartEvent; // Called at the beginning of DoExit
     protected
          fBoundsValidation: Boolean; // Is Bounds Validation On
          fBoundsValidationType: TESBBoundsValidationType; // What sort of Validation problem
          fCheckforErrors: Boolean; // Check for errors in Conversions
          fColorFontNeg: TColor; // Font Color to display negative numbers
          fColorFontPos: TColor; // Font Color to display non-negative numbers
          fConvertOK: Boolean; // True when component has not been entered or has been successfully exited.
          fIgnoreConvertError: Boolean; // Controls how FConvertError is handled
          fOnConvertError: TESBConvertErrorEvent; // Called if a Conversion error occurs on Exiting
          fYearValidation: Boolean; // Enable Year Bounds Validation

          procedure Change; override;
          procedure DoEnter; override;
          procedure DoExit; override;
          procedure DoBoundsValidation; virtual;
          procedure DisplayText; override;
          procedure KeyPress (var Key: Char); override;

          procedure SetBoundsValidation (Value: Boolean); virtual;
          procedure SetColorFontNeg (Value: TColor);
          procedure SetColorFontPos (Value: TColor);
          function GetMaxLength: Integer;
          procedure SetMaxLength (Value: Integer);
          function GetConvertOK: Boolean;
          function GetYearValidation: Boolean;
          function GetIgnoreConvertError: Boolean;
          procedure SetIgnoreConvertError (Value: Boolean);
          function GetOnConvertError: TESBConvertErrorEvent;
          procedure SetOnConvertError (Value: TESBConvertErrorEvent);

          procedure SetColors2Defaults; override;
     public
          //: Creates the Edit Component.
          constructor Create (AOwner: TComponent); override;

          {: Font Color for the field when it contains a Negative Value.
           Color is changed, if required, when the field is exited.
           Font.Color Property is ignored. }
          property ColorFontNeg: TColor
               read fColorFontNeg
               write SetColorFontNeg
               default DefNegFontColor2;
          {: Font Color for the field when it contains a non-Negative Value
           Color is changed, if required, when the field is exited.
           Font.Color Property is ignored }
          property ColorFontPos: TColor
               read fColorFontPos
               write SetColorFontPos
               default DefPosFontColor2;

     published
          {: This controls whether Bound Validation Checking and
           resultant Error Messages will be displayed. }
          property BoundsEnabled: Boolean
               read fBoundsValidation
               write SetBoundsValidation
               default False;
          {: Overriden MaxLength that still works the same way that
           the Standard TEdit property does. For ZeroPad to work
           MaxLength must be greater 0. }
          property MaxLength: Integer
               read GetMaxLength
               write SetMaxLength
               default 0;

          {: Allows the User to handle the Bounds Validation Error. Event will only
           be called when there Validation is Enabled and there is
           a Validation Error. }
          property OnBoundsError: TESBBoundsValidationEvent
               read fOnBoundsError
               write fOnBoundsError;
          {: Exit Start Event is called at the start of the DoExit but before the
           final conversion of text to value and before any Bounds Checking
           or Conversion Checking is done. Set FurtherChecking to False to
           turn off Conversion & Bounds Checking. The value of Text can be
           altered. }
          property OnExitStart: TESBExitStartEvent
               read fOnExitStart
               write fOnExitStart;

          //: Published property from TCustomEdit
          property Align;
          //: Published property from TCustomEdit
          property Anchors;
          //: Published property from TCustomEdit
          property AutoSelect;
          //: Published property from TCustomEdit
          property BiDiMode;
          //: Published property from TCustomEdit
          property BorderStyle;
          //: Published property from TCustomEdit
          property CharCase;
          //property Color;
          //: Published property from TCustomEdit
          property Constraints;
          //: Published property from TCustomEdit
          property Ctl3D;
          //: Published property from TCustomEdit
          property DragCursor;
          //: Published property from TCustomEdit
          property DragKind;
          //: Published property from TCustomEdit
          property DragMode;
          //: Published property from TCustomEdit
          property Enabled;
          //: Published property from TCustomEdit
          property HideSelection;
          //: Published property from TCustomEdit
          property ImeMode;
          //: Published property from TCustomEdit
          property ImeName;
          //: Published property from TCustomEdit
          property OEMConvert;
          //: Published property from TCustomEdit
          property ParentBiDiMode;
          //property ParentColor;
          //: Published property from TCustomEdit
          property ParentCtl3D;
          //: Published property from TCustomEdit
          property ParentShowHint;
          //: Published property from TCustomEdit
          property PasswordChar;
          //: Published property from TCustomEdit
          property PopupMenu;
          //property ReadOnly;
                  //: Published property from TCustomEdit
          property ShowHint;
          //: Published property from TCustomEdit
          property TabOrder;
          //: Published property from TCustomEdit
          property TabStop;
          //: Published property from TCustomEdit
          property Visible;
          //: Published property from TCustomEdit
          property OnClick;
          {$IFNDEF BelowD5}
          //: Published property from TCustomEdit
          property OnContextPopup;
          {$ENDIF}
          //: Published property from TCustomEdit
          property OnChange;
          //: Published property from TCustomEdit
          property OnDblClick;
          //: Published property from TCustomEdit
          property OnDragDrop;
          //: Published property from TCustomEdit
          property OnDragOver;
          //: Published property from TCustomEdit
          property OnEndDock;
          //: Published property from TCustomEdit
          property OnEndDrag;
          //: Published property from TCustomEdit
          property OnKeyDown;
          //: Published property from TCustomEdit
          property OnKeyUp;
          //: Published property from TCustomEdit
          property OnMouseDown;
          //: Published property from TCustomEdit
          property OnMouseMove;
          //: Published property from TCustomEdit
          property OnMouseUp;
          //: Published property from TCustomEdit
          property OnMouseWheel;
          //: Published property from TCustomEdit
          property OnMouseWheelDown;
          //: Published property from TCustomEdit
          property OnMouseWheelUp;
          //: Published property from TCustomEdit
          property OnStartDock;
          //: Published property from TCustomEdit
          property OnStartDrag;
     end;

implementation

uses
     Forms, SysUtils, Windows,
     ESBPCS_RS_Globals,
     ESBPCSConvert, ESBPCSMsgs;

constructor TESBCustomEdit.Create (AOwner: TComponent);
begin
     inherited Create (AOwner);
     fStrValue := '';
     fStoreValue := True;
     fNoDisplayUpdate := False;
     fInUpdate := False;
     fAlignment := taLeftJustify;
     fFlat := False;
     fFlatBorder := ESBBorderSize;
     fLineEdit := False;
     fValidChar := [#32..#255];
     fValidCharHold := fValidChar;
     fNull := False;
     fNullStr := ESBNullStr;
     fAllowKbdNull := True;
     fBlankWhenNull := False;
     fColor_Defaults := True;
     fNumPadDecimal := False;
     fNumPadPressed := False;
     fBlankIsNull := False;
     SetColors2Defaults;
     UpdateColors;
end;

procedure TESBCustomEdit.SetColors2Defaults;
begin
     fColorRO := ESBROColor;
     fColorRW := ESBRWColor;
     fColorFocus := ESBFocusColor;
     fColorBorderFocus := ESBBorderFocusColor;
     fColorBorderUnfocus := ESBBorderNonFocusColor;
     fColorDisabled := ESBDisabledColor;
end;

procedure TESBCustomEdit.SetColor_Defaults (Value: Boolean);
begin
     fColor_Defaults := Value;
     if fColor_Defaults then
     begin
          SetColors2Defaults;
          UpdateColors;
     end;
end;

function TESBCustomEdit.ValueStored: Boolean;
begin
     Result := fStoreValue;
end;

procedure TESBCustomEdit.Convert2Value;
begin
     // Currently Do Nothing
end;

procedure TESBCustomEdit.SelectNone;
begin
     SelLength := 0;
     SelStart := 0;
end;

function TESBCustomEdit.IsClear: Boolean;
begin
     Result := (inherited Text = '') or fNull;
end;

function TESBCustomEdit.GetStrValue: string;
begin
     fStrValue := inherited Text;
     if Null then
          Result := ''
     else
          Result := fStrValue;
end;

procedure TESBCustomEdit.SetStrValue (const Value: string);
begin
     if fBlankIsNull and (Value = '') then
     begin
          fNull := True;
          DisplayText;
          Exit;
     end;

     if (Value <> fStrValue) then
     begin
          fStrValue := Value;

          if fNull then
          begin
               if fBlankWhenNull then
                    fNull := (Value = '')
               else
                    fNull := (Value = fNullStr);
          end;

          inherited Text := fStrValue;
          Convert2Value;
          if not fNoDisplayUpdate then
               DisplayText;
     end;
end;

procedure TESBCustomEdit.DisplayText;
begin
     if fNull then
     begin
          if fBlankWhenNull then
               inherited Text := ''
          else
               inherited Text := fNullStr
     end;
end;

procedure TESBCustomEdit.SetBlankWhenNull (Value: Boolean);
begin
     if fBlankWhenNull <> Value then
     begin
          fBlankWhenNull := Value;
          DisplayText;
     end;
end;

procedure TESBCustomEdit.WMPaste (var Msg: TMessage);
begin
     if not fReadOnly then
     begin
          fNull := False;
          inherited;
     end;
end;

procedure TESBCustomEdit.WMCut (var Msg: TMessage);
begin
     if not fReadOnly then
     begin
          inherited;
     end;
end;

function TESBCustomEdit.StoreNullStr: Boolean;
begin
     Result := (fNullStr <> ESBNullStr) and not fBlankWhenNull;
end;

procedure TESBCustomEdit.SetNullStr (const Value: string);
begin
     if Value <> fNullStr then
     begin
          fNullStr := Value;
          DisplayText;
     end;
end;

procedure TESBCustomEdit.SetNull (Value: Boolean);
begin
     if Value <> fNull then
     begin
          fNull := Value;
          DisplayText;
     end;
end;

function TESBCustomEdit.GetVersion: string;
begin
     Result := ESBPCSVersion;
end;

procedure TESBCustomEdit.SetVersion (const Value: string);
begin
     // Do nothing
end;

procedure TESBCustomEdit.SetFlat (Value: Boolean);
begin
     if Value <> fFlat then
     begin
          fFlat := Value;
          if not fFlat then
               fLineEdit := False;
          if fFlat then
               FlattenControl
          else
               RecreateWnd;
     end;
end;

procedure TESBCustomEdit.SetLineEdit (Value: Boolean);
begin
     if Value <> fLineEdit then
     begin
          fLineEdit := Value;
          if fLineEdit then
               fFlat := True;
          if fLineEdit then
               FlattenControl
          else
               RecreateWnd;
     end;
end;

procedure TESBCustomEdit.SetFlatBorder (Value: Integer);
begin
     if Value < 1 then
          Value := 1
     else if Value > 2 then
          Value := 2;
     if Value <> fFlatBorder then
     begin
          fFlatBorder := Value;
          if fFlat then
               FlattenControl;
     end;
end;

procedure TESBCustomEdit.CNKeyDown (var Msg: TWMKeyDown);
begin
     if Assigned (fOnCNKeyDown) then
          fOnCNKeyDown (Self, Msg.CharCode, KeyDataToShiftState (Msg.KeyData));
     inherited;
end;

procedure TESBCustomEdit.KeyPress (var Key: Char);
begin
     if Assigned (fOnKeyPress) then
          fOnKeyPress (Self, Key);
     KeyProcess (Key);
end;

procedure TESBCustomEdit.KeyProcess (var Key: Char);
begin
     if (Key = #13) and ESBEnterAsTab then
     begin
          Key := #0;
          SendMessage (GetParentForm (Self).Handle, WM_NEXTDLGCTL, 0, 0);
     end
     else if (Key = #27) and ESBEscAsUndo then
     begin
          Key := #0;
          Undo;
     end
     else if (Key = #14) and fAllowKbdNull then
     begin
          SetNull (True);
          if Assigned (fOnNull) then
               fOnNull (Self);
          Key := #0;
     end
     else if Key = ^A then
     begin
          SelectAll;
          Key := #0
     end
     else if fValidChar <> [] then
     begin
          if (Key >= #32) and not (Key in fValidChar) then
          begin
               Key := #0;
               MessageBeep (0);
          end
          else if (Key in fValidChar) then
          begin
               if fNull then
               begin
                    SetNull (False);
                    Clear;
               end;
          end
     end
     else if (Key >= #32) then
     begin
          Key := #0;
          MessageBeep (0);
     end;
end;

procedure TESBCustomEdit.KeyDown (var Key: Word; Shift: TShiftState);
begin
     if Shift = [] then
     begin
          case Key of
               VK_Delete:
                    begin
                         if ReadOnly then
                              Key := 0;
                    end;
               VK_Decimal:
                    begin
                         if fNumPadDecimal then
                              fNumPadPressed := True;
                    end;
          end;
     end
     else if Shift = [ssShift] then
     begin
          case Key of
               VK_Insert:
                    begin
                         if ReadOnly then
                              Key := 0
                    end;
          end;
     end;

     if ESBArrowsAsTab then
     begin
          if Shift = [] then
          begin
               case Key of
                    VK_UP:
                         begin
                              Key := 0;
                              SendMessage (GetParentForm (Self).Handle, WM_NEXTDLGCTL, 1, 0);
                         end;
                    VK_DOWN:
                         begin
                              Key := 0;
                              SendMessage (GetParentForm (Self).Handle, WM_NEXTDLGCTL, 0, 0);
                         end;
                    VK_Delete:
                         begin
                              if ReadOnly then
                                   Key := 0;
                         end;
                    VK_Decimal:
                         begin
                              if fNumPadDecimal then
                                   Key := Ord (FormatSettings.DecimalSeparator);
                         end;
               end;
          end;
     end;
     inherited KeyDown (Key, Shift);
end;

procedure TESBCustomEdit.SetAlignment (Value: TAlignment);
begin
     if Value <> fAlignment then
     begin
          fAlignment := value;
          RecreateWnd;
     end;
end;

procedure TESBCustomEdit.CMFontChanged (var Msg: TMessage);
begin
     inherited;
     UpdateColors;
end;

procedure TESBCustomEdit.CMEnabledChanged (var Msg: TMessage);
begin
     inherited;
     UpdateColors
end;

procedure TESBCustomEdit.CMMouseEnter (var Msg: TMessage);
begin
     inherited;
     fMouseOver := True;
     if fFlat then
          FlattenControl;
     if Assigned (fOnMouseEnter) then
          fOnMouseEnter (Self);
end;

procedure TESBCustomEdit.CMMouseLeave (var Msg: TMessage);
begin
     inherited;
     fMouseOver := False;
     if fFlat then
          FlattenControl;
     if Assigned (fOnMouseExit) then
          fOnMouseExit (Self);
end;

procedure TESBCustomEdit.CreateParams (var Params: TCreateParams);
begin
     inherited CreateParams (Params);
     case Alignment of
          taLeftJustify: Params.Style := Params.Style or ES_LEFT;
          taRightJustify: Params.Style := Params.Style or ES_RIGHT;
          taCenter: Params.Style := Params.Style or ES_CENTER;
     end;
     if PasswordChar <> #0 then
          Params.Style := Params.Style or ES_PASSWORD
     else if Alignment <> taLeftJustify then
          Params.Style := Params.Style or ES_MULTILINE;

     if fReadOnly then
          Params.Style := Params.Style or ES_READONLY;

end;

procedure TESBCustomEdit.WMNCPaint (var Msg: TMessage);
begin
     inherited;
     if fFlat then
          FlattenControl;
end;

procedure TESBCustomEdit.FlattenControl;
var
     DC: HDC;
     Rect: TRect;
     DispColor, BorderColor1, BorderColor2: TColor;
     BorderBrush, DisplayBrush: HBRUSH;
     Pen, OldPen: HPEN;
     Pt: PPoint;
     FocusColors: Boolean;
begin
     if fInUpdate then
          Exit;

     if fColorRW = clNone then
     begin
          ParentColor := False;
          ParentColor := True;
     end;

     if fColorBorderFocus = clNone then
     begin
          if fColorBorderUnfocus = clNone then
          begin
               if fColorRW = clNone then
                    BorderColor1 := Color
               else
                    BorderColor1 := fColorRW
          end
          else
               BorderColor1 := fColorBorderUnfocus
     end
     else
          BorderColor1 := fColorBorderFocus;

     if fColorBorderUnfocus = clNone then
     begin
          if fColorBorderFocus = clNone then
          begin
               if fColorRW = clNone then
                    BorderColor2 := Color
               else
                    BorderColor2 := fColorRW
          end
          else
               BorderColor2 := fColorBorderFocus
     end
     else
          BorderColor2 := fColorBorderUnfocus;

     FocusColors := not (csDesigning in ComponentState) and (fFocused or fMouseOver);

     if FocusColors then
          BorderBrush := CreateSolidBrush (ColorToRGB (BorderColor1))
     else
          BorderBrush := CreateSolidBrush (ColorToRGB (BorderColor2));

     if not Enabled then
     begin
          if fColorDisabled = clNone then
          begin
               if ColorRW = clNone then
                    DispColor := Color
               else
                    DispColor := fColorRW;
          end
          else
               DispColor := fColorDisabled;
     end
     else if fReadOnly then
     begin
          if fColorRO = clNone then
          begin
               if ColorRW = clNone then
                    DispColor := Color
               else
                    DispColor := fColorRW;
          end
          else
               DispColor := fColorRO;
     end
     else if FocusColors and (fColorFocus <> clNone) then
     begin
          DispColor := fColorFocus
     end
     else if ColorRW = clNone then
          DispColor := Color
     else
          DispColor := fColorRW;

     DisplayBrush := CreateSolidBrush (ColorToRGB (DispColor));

     DC := GetWindowDC (Handle);
     try
          GetWindowRect (Handle, Rect);
          OffsetRect (Rect, -Rect.Left, -Rect.Top);
          Color := DispColor;
          if fLineEdit then
          begin
               FrameRect (DC, Rect, DisplayBrush);
               InflateRect (Rect, -1, -1);
               FrameRect (DC, Rect, DisplayBrush);
               InflateRect (Rect, -1, -1);
               Pen := CreatePen (PS_Solid, fFlatBorder, ColorToRGB (BorderColor1));
               OldPen := SelectObject (DC, Pen);
               New (Pt);
               try
                    MoveToEx (DC, Rect.Left - 2, Rect.Bottom + 1, Pt);
                    LineTo (DC, Rect.Right + 2, Rect.Bottom + 1);
                    Rect.Bottom := Rect.Bottom - 1;
               finally
                    Dispose (Pt);
                    SelectObject (DC, OldPen);
                    DeleteObject (Pen);
               end;
          end
          else
          begin
               FrameRect (DC, Rect, BorderBrush);
               InflateRect (Rect, -1, -1);
               if fFlatBorder = 2 then
               begin
                    FrameRect (DC, Rect, BorderBrush);
                    InflateRect (Rect, -1, -1);
               end;
          end;
          FrameRect (DC, Rect, DisplayBrush);
     finally
          ReleaseDC (Handle, DC);
          DeleteObject (DisplayBrush);
          DeleteObject (BorderBrush);
     end;
end;

procedure TESBCustomEdit.BeginUpdate;
begin
     fInUpdate := True;
end;

procedure TESBCustomEdit.EndUpdate;
begin
     fInUpdate := False;
     UpdateColors;
end;

procedure TESBCustomEdit.UpdateColors;
begin
     if fInUpdate then
          Exit;

     if fColorRW = clNone then
     begin
          ParentColor := False;
          ParentColor := True;
     end;

     if fFlat then
          FlattenControl
     else if not Enabled then
     begin
          if fColorDisabled = clNone then
          begin
               if fColorRW <> clNone then
                    Color := ColorRW;
          end
          else
               Color := fColorDisabled;
     end
     else if fReadOnly then
     begin
          if fColorRO = clNone then
          begin
               if fColorRW <> clNone then
                    Color := ColorRW;
          end
          else
               Color := fColorRO
     end
     else if fFocused and (fColorFocus <> clNone) then
          Color := fColorFocus
     else if fColorRW <> clNone then
          Color := fColorRW;

     Invalidate;
end;

procedure TESBCustomEdit.SetColorFocus (Value: TColor);
begin
     if Value <> fColorFocus then
     begin
          fColor_Defaults := False;
          fColorFocus := value;
          UpdateColors;
     end;
end;

procedure TESBCustomEdit.SetColorBorderFocus (Value: TColor);
begin
     if Value <> fColorBorderFocus then
     begin
          fColor_Defaults := False;
          fColorBorderFocus := value;
          UpdateColors;
     end;
end;

procedure TESBCustomEdit.SetColorBorderUnfocus (Value: TColor);
begin
     if Value <> fColorBorderUnfocus then
     begin
          fColor_Defaults := False;
          fColorBorderUnfocus := value;
          UpdateColors;
     end;
end;

procedure TESBCustomEdit.SetColorDisabled (Value: TColor);
begin
     if Value <> fColorDisabled then
     begin
          fColor_Defaults := False;
          fColorDisabled := value;
          if not Enabled then
          begin
               Enabled := True; // Toggle Enabled to update Color
               Enabled := False;
          end;
     end;
end;

procedure TESBCustomEdit.SetColorRO (Value: TColor);
begin
     if Value <> fColorRO then
     begin
          fColor_Defaults := False;
          fColorRO := value;
          UpdateColors;
     end;
end;

procedure TESBCustomEdit.SetColorRW (Value: TColor);
begin
     if Value <> fColorRW then
     begin
          fColor_Defaults := False;
          fColorRW := value;
          UpdateColors;
     end;
end;

procedure TESBCustomEdit.SetReadOnly (Value: Boolean);
begin
     if fReadOnly <> Value then
     begin
          fReadOnly := Value;
          inherited ReadOnly := Value;
          if fReadOnly then
               fValidChar := []
          else
               fValidChar := fValidCharHold;
          if ESBNoTabStopOnReadOnly then
               TabStop := not fReadOnly;
          UpdateColors;
          Invalidate;
     end;
end;

procedure TESBCustomEdit.DoEnter;
begin
     fFocused := True;
     UpdateColors;
     if AutoSelect then
          SelectAll; // When entering the field start with whole field selected
     // So overwriting will take place if typing starts
     if Assigned (fOnEnter) then
          fOnEnter (Self);
end;

procedure TESBCustomEdit.DoExit;
begin
     fFocused := False;
     UpdateColors;
     if Assigned (fOnExit) then
          fOnExit (Self);
end;

procedure TESBCustomEdit.MouseUp (Button: TMouseButton; Shift: TShiftState;
     X, Y: Integer);
begin
     inherited;
     if Button = mbRight then
     begin
          fFocused := False;
          fMouseOver := False;
          UpdateColors;
     end;
end;

constructor TESBPCSEdit.Create (AOwner: TComponent);
begin
     inherited Create (AOwner);
     fTrimTrailing := True;
     fTrimLeading := False;
     fProperAdjust := False;
     fAutoAdvance := False;
end;

procedure TESBPCSEdit.DoExit;
var
     S: string;
begin
     if not fNull then
     begin
          S := Text;
          if fTrimTrailing then
               S := TrimRight (S);
          if fTrimLeading then
               S := TrimLeft (S);
          if fProperAdjust then
               S := ESBProperStr (S);
          if S <> Text then
               Text := S;

          if fBlankIsNull and (S = '') then
          begin
               fNull := True;
               if fBlankWhenNull then
                    Text := ''
               else
                    Text := fNullStr
          end;
     end;
     inherited DoExit;
end;

function TESBPCSEdit.LowerText: string;
begin
     Result := AnsiLowerCase (Trim (Text));
end;

function TESBPCSEdit.TrimmedText: string;
begin
     Result := Trim (Text);
end;

function TESBPCSEdit.UpperText: string;
begin
     Result := AnsiUpperCase (Trim (Text));
end;

function TESBPCSEdit.ProperText: string;
begin
     Result := ESBProperStr (Trim (Text));
end;

procedure TESBPCSEdit.KeyUp (var Key: Word; Shift: TShiftState);
begin
     inherited KeyUp (Key, Shift);

     if not (csLoading in ComponentState) and (fAutoAdvance = True) and
          (MaxLength > 0) and (MaxLength = Length (Text)) and (Key >= 32) then
     begin
          SendMessage (GetParentForm (Self).Handle, WM_NEXTDLGCTL, 0, 0);
     end;
end;

constructor TESBBaseEdit.Create (AOwner: TComponent);
begin
     inherited Create (AOwner);
     fAlignment := taLeftJustify;
     fBoundsValidation := False;
     fBoundsValidationType := evtNone;
     fMaxLength := 0;
     fCheckforErrors := False;
     Width := 81;
     fConvertOK := True;
end;

procedure TESBBaseEdit.SetColors2Defaults;
begin
     inherited SetColors2Defaults;
     fColorFontNeg := ESBNegFontColor;
     fColorFontPos := ESBPosFontColor;
     DisplayText;
end;

function TESBBaseEdit.GetConvertOK: Boolean;
begin
     Result := fConvertOK;
end;

function TESBBaseEdit.GetYearValidation: Boolean;
begin
     Result := fYearValidation;
end;

function TESBBaseEdit.GetOnConvertError: TESBConvertErrorEvent;
begin
     Result := fOnConvertError;
end;

procedure TESBBaseEdit.SetOnConvertError (Value: TESBConvertErrorEvent);
begin
     fOnConvertError := Value;
end;

function TESBBaseEdit.GetIgnoreConvertError: Boolean;
begin
     Result := fIgnoreConvertError;
end;

procedure TESBBaseEdit.SetIgnoreConvertError (Value: Boolean);
begin
     fIgnoreConvertError := Value;
end;

procedure TESBBaseEdit.Change;
begin
     if not (csLoading in ComponentState) then
     begin
          Convert2Value;
          inherited Change;
     end;
end;

procedure TESBBaseEdit.DoEnter;
begin
     inherited DoEnter;
     fConvertOK := False;
end;

procedure TESBBaseEdit.DoExit;
var
     FurtherChecking: Boolean;
begin
     FurtherChecking := True;
     if Assigned (fOnExitStart) then
     begin
          fOnExitStart (Self, fStrValue, FurtherChecking);
          inherited Text := fStrValue;
     end;
     if not fIgnoreConvertError then
     begin
          try
               fCheckforErrors := FurtherChecking;
               Convert2Value;
          except
               fCheckforErrors := False;
               if Assigned (fOnConvertError) then
               begin
                    fOnConvertError (Self, Text);
                    Self.SetFocus;
                    Exit;
               end
               else
                    raise;
          end;

          fCheckforErrors := False;
          DisplayText; // and that the Edit Box displays properly formatted value

          if (fBoundsValidation or fYearValidation) and FurtherChecking then // Handle Bounds Validation if enabled
               DoBoundsValidation;
     end;

     fConvertOK := True;
     inherited DoExit;
end;

function TESBBaseEdit.GetMaxLength: Integer;
begin
     fMaxLength := inherited MaxLength;
     Result := fMaxLength;
end;

procedure TESBBaseEdit.SetMaxLength (Value: Integer);
begin
     if Value <> fMaxLength then
     begin
          fMaxLength := Value;
          inherited MaxLength := Value;
          DisplayText;
     end;
end;

procedure TESBBaseEdit.SetColorFontNeg (Value: TColor);
begin
     if fColorFontNeg <> Value then
     begin
          fColor_Defaults := False;
          fColorFontNeg := Value;
          DisplayText;
     end;
end;

procedure TESBBaseEdit.SetColorFontPos (Value: TColor);
begin
     if fColorFontPos <> Value then
     begin
          fColor_Defaults := False;
          fColorFontPos := Value;
          DisplayText;
     end;
end;

procedure TESBBaseEdit.SetBoundsValidation (Value: Boolean);
begin
     if fBoundsValidation <> Value then
     begin
          fBoundsValidation := Value;
     end;
end;

procedure TESBBaseEdit.DoBoundsValidation;
begin
     // This is really a dummy routine as it should normally be overriden
     if fBoundsValidation then
     begin
          if Assigned (fOnBoundsError) then
               fOnBoundsError (Self, Text, fBoundsValidationType)
          else
               ErrorMsg (rsUnaccept);
     end;
end;

procedure TESBBaseEdit.KeyPress (var Key: Char);
begin
     if Assigned (fOnKeyPress) then
          fOnKeyPress (Self, Key);

     KeyProcess (Key);
end;

procedure TESBBaseEdit.DisplayText;
begin
     if fNull then
     begin
          if fBlankWhenNull then
          begin
               inherited Text := '';
               Text := ''
          end
          else
          begin
               inherited Text := fNullStr;
               Text := fNullStr
          end;
     end
     else
          Text := inherited Text;
end;

end.
