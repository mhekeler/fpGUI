{
    fpGUI  -  Free Pascal GUI Library

    Copyright (C) 2006 - 2008 See the file AUTHORS.txt, included in this
    distribution, for details of the copyright.

    See the file COPYING.modifiedLGPL, included in this distribution,
    for details about redistributing fpGUI.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    Description:
      Defines a MainMenu Bar, Popup Menu and Menu Item controls.
}

unit gui_menu;

{$mode objfpc}{$H+}

{
  TODO:
    * Refactor the HotKey painting code into Canvas.DrawString so that other
      widgets like TfpgButton could also use it.
    * Global keyboard activation of menu items are still missing.
}

interface

uses
  Classes,
  SysUtils,
  gfxbase,
  fpgfx,
  gfx_widget,
  gfx_popupwindow,
  gfx_UTF8utils,
  gfx_command_intf;
  
type
  TfpgHotKeyDef = string;
  
  // forward declarations
  TfpgPopupMenu = class;
  TfpgMenuBar = class;
  
  
  TfpgMenuItem = class(TComponent, ICommandHolder)
  private
    FCommand: ICommand;
    FEnabled: boolean;
    FHotKeyDef: TfpgHotKeyDef;
    FOnClick: TNotifyEvent;
    FSeparator: boolean;
    FSubMenu: TfpgPopupMenu;
    FText: string;
    FVisible: boolean;
    procedure   SetEnabled(const AValue: boolean);
    procedure   SetHotKeyDef(const AValue: TfpgHotKeyDef);
    procedure   SetSeparator(const AValue: boolean);
    procedure   SetText(const AValue: string);
    procedure   SetVisible(const AValue: boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure   Click;
    function    Selectable: boolean;
    function    GetAccelChar: string;
    procedure   DrawText(ACanvas: TfpgCanvas; x, y: TfpgCoord);
    function    GetCommand: ICommand;
    procedure   SetCommand(ACommand: ICommand);
    property    Text: string read FText write SetText;
    property    HotKeyDef: TfpgHotKeyDef read FHotKeyDef write SetHotKeyDef;
    property    Separator: boolean read FSeparator write SetSeparator;
    property    Visible: boolean read FVisible write SetVisible;
    property    Enabled: boolean read FEnabled write SetEnabled;
    property    SubMenu: TfpgPopupMenu read FSubMenu write FSubMenu;
    property    OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;
  
  
  // Actual Menu Items are stored in TComponent's Components property
  // Visible only items are stored in FItems just before a paint
  TfpgPopupMenu = class(TfpgPopupWindow)
  private
    FBackgroundColor: TfpgColor;
    FBeforeShow: TNotifyEvent;
    FMargin: TfpgCoord;
    FTextMargin: TfpgCoord;
    procedure   SetBackgroundColor(const AValue: TfpgColor);
    procedure   DoSelect;
    procedure   CloseSubmenus;
    function    GetItemPosY(index: integer): integer;
    function    CalcMouseRow(y: integer): integer;
    function    VisibleCount: integer;
    function    VisibleItem(ind: integer): TfpgMenuItem;
    function    MenuFocused: boolean;
    function    SearchItemByAccel(s: string): integer;
  protected
    FMenuFont: TfpgFont;
    FMenuAccelFont: TfpgFont;
    FMenuDisabledFont: TfpgFont;
    FSymbolWidth: integer;
    FItems: TList;
    FFocusItem: integer;
    procedure   HandleMouseExit; override;
    procedure   HandleMouseMove(x, y: integer; btnstate: word; shiftstate: TShiftState); override;
    procedure   HandleLMouseDown(x, y: integer; shiftstate: TShiftState); override;
    procedure   HandleLMouseUp(x, y: integer; shiftstate: TShiftState); override;
    procedure   HandleKeyPress(var keycode: word; var shiftstate: TShiftState; var consumed: boolean); override;
    procedure   HandlePaint; override;
    procedure   HandleShow; override;
    procedure   DrawItem(mi: TfpgMenuItem; rect: TfpgRect); virtual;
    procedure   DrawRow(line: integer; focus: boolean); virtual;
    function    ItemHeight(mi: TfpgMenuItem): integer; virtual;
    procedure   PrepareToShow;
  public
    OpenerPopup: TfpgPopupMenu;
    OpenerMenuBar: TfpgMenuBar;
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Close; override;
    function    AddMenuItem(const AMenuName: string; const hotkeydef: string; HandlerProc: TNotifyEvent): TfpgMenuItem;
    function    MenuItemByName(const AMenuName: string): TfpgMenuItem;
    property    BackgroundColor: TfpgColor read FBackgroundColor write SetBackgroundColor;
    property    BeforeShow: TNotifyEvent read FBeforeShow write FBeforeShow;
  end;
  
  
  // Actual Menu Items are stored in TComponents Components property
  // Visible only items are stored in FItems just before a paint
  TfpgMenuBar = class(TfpgWidget)
  private
    FBackgroundColor: TfpgColor;
    FBeforeShow: TNotifyEvent;
    FLightColor: TfpgColor;
    FDarkColor: TfpgColor;
    FPrevFocusItem: integer;
    FFocusItem: integer;
    procedure   SetBackgroundColor(const AValue: TfpgColor);
    procedure   SetFocusItem(const AValue: integer);
    procedure   DoSelect;
    procedure   CloseSubmenus;
    function    ItemWidth(mi: TfpgMenuItem): integer;
  protected
    FItems: TList;  // stores visible items only
    property    FocusItem: integer read FFocusItem write SetFocusItem;
    procedure   PrepareToShow;
    function    VisibleCount: integer;
    function    VisibleItem(ind: integer): TfpgMenuItem;
    procedure   HandleShow; override;
    procedure   HandleMouseMove(x, y: integer; btnstate: word; shiftstate: TShiftState); override;
    procedure   HandleLMouseDown(x, y: integer; shiftstate: TShiftState); override;
    procedure   HandleKeyPress(var keycode: word; var shiftstate: TShiftState; var consumed: boolean); override;
    procedure   HandlePaint; override;
    function    CalcMouseCol(x: integer): integer;
    function    GetItemPosX(index: integer): integer;
    function    MenuFocused: boolean;
    function    SearchItemByAccel(s: string): integer;
    procedure   ActivateMenu;
    procedure   DeActivateMenu;
    procedure   DrawColumn(col: integer; focus: boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    AddMenuItem(const AMenuTitle: string; OnClickProc: TNotifyEvent): TfpgMenuItem;
    property    BackgroundColor: TfpgColor read FBackgroundColor write SetBackgroundColor;
    property    BeforeShow: TNotifyEvent read FBeforeShow write FBeforeShow;
  end;


implementation

var
  uFocusedPopupMenu: TfpgPopupMenu;


{ TfpgMenuItem }

procedure TfpgMenuItem.SetText(const AValue: string);
begin
  if FText=AValue then exit;
  FText:=AValue;
end;

procedure TfpgMenuItem.SetVisible(const AValue: boolean);
begin
  if FVisible=AValue then exit;
  FVisible:=AValue;
end;

procedure TfpgMenuItem.SetHotKeyDef(const AValue: TfpgHotKeyDef);
begin
  if FHotKeyDef=AValue then exit;
  FHotKeyDef:=AValue;
end;

procedure TfpgMenuItem.SetEnabled(const AValue: boolean);
begin
  if FEnabled=AValue then exit;
  FEnabled:=AValue;
end;

procedure TfpgMenuItem.SetSeparator(const AValue: boolean);
begin
  if FSeparator=AValue then exit;
  FSeparator:=AValue;
end;

constructor TfpgMenuItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Text := '';
  HotKeyDef := '';
  FSeparator := False;
  FVisible := True;
  FEnabled := True;
  FSubMenu := nil;
  FOnClick := nil;
end;

procedure TfpgMenuItem.Click;
begin
  if Assigned(FOnClick) then
    FOnClick(self);
end;

function TfpgMenuItem.Selectable: boolean;
begin
  Result := Enabled and Visible and (not Separator);
end;

function TfpgMenuItem.GetAccelChar: string;
var
  p: integer;
begin
  p := UTF8Pos('&', Text);
  if p > 0 then
  begin
    Result := UTF8Copy(Text, p+1, 1);
  end
  else
    Result := '';
end;

procedure TfpgMenuItem.DrawText(ACanvas: TfpgCanvas; x, y: TfpgCoord);
var
  s: string;
  p: integer;
  achar: string;
begin
//  writeln('DrawText  x:', x, '  y:', y);
  if not Enabled then
    ACanvas.SetFont(fpgStyle.MenuDisabledFont)
  else
    ACanvas.SetFont(fpgStyle.MenuFont);

  achar := '&';
  s := Text;

  repeat
    p := UTF8Pos(achar, s);
    if p > 0 then
    begin
      // first part of text before the & sign
      ACanvas.DrawString(x, y, UTF8Copy(s, 1, p-1));
      inc(x, fpgStyle.MenuFont.TextWidth(UTF8Copy(s, 1, p-1)));
      if UTF8Copy(s, p+1, 1) = achar then
      begin
        // Do we need to paint a actual & sign (create via && in item text)
        ACanvas.DrawString(x, y, achar);
        inc(x, fpgStyle.MenuFont.TextWidth(achar));
      end
      else
      begin
        // Draw the HotKey text
        if Enabled then
          ACanvas.SetFont(fpgStyle.MenuAccelFont);
        ACanvas.DrawString(x, y, UTF8Copy(s, p+1, 1));
        inc(x, ACanvas.Font.TextWidth(UTF8Copy(s, p+1, 1)));
        if Enabled then
          ACanvas.SetFont(fpgStyle.MenuFont);
      end;
      s := UTF8Copy(s, p+2, UTF8Length(s));
    end;  { if }
  until p < 1;

  // Draw the remaining text after the & sign
  if UTF8Length(s) > 0 then
    ACanvas.DrawString(x, y, s);
end;

function TfpgMenuItem.GetCommand: ICommand;
begin
  Result := FCommand;
end;

procedure TfpgMenuItem.SetCommand(ACommand: ICommand);
begin
  FCommand := ACommand;
end;

{ TfpgMenuBar }

procedure TfpgMenuBar.SetBackgroundColor(const AValue: TfpgColor);
begin
  if FBackgroundColor=AValue then exit;
  FBackgroundColor:=AValue;
end;

procedure TfpgMenuBar.SetFocusItem(const AValue: integer);
begin
  if FFocusItem = AValue then
    Exit;
  FPrevFocusItem := FFocusItem;
  FFocusItem := AValue;
end;

procedure TfpgMenuBar.PrepareToShow;
var
  n: integer;
  mi: TfpgMenuItem;
begin
  if Assigned(FBeforeShow) then
    FBeforeShow(self);

  FItems.Count := 0;
  // Collecting visible items
  for n := 0 to ComponentCount-1 do
  begin
    if Components[n] is TfpgMenuItem then
    begin
      mi := TfpgMenuItem(Components[n]);
      if mi.Visible then
        FItems.Add(mi);
    end;
  end;
end;

function TfpgMenuBar.VisibleCount: integer;
begin
  Result := FItems.Count;
end;

function TfpgMenuBar.VisibleItem(ind: integer): TfpgMenuItem;
begin
  if (ind < 1) or (ind > FItems.Count) then
    Result := nil
  else
    Result := TfpgMenuItem(FItems.Items[ind-1]);
end;

procedure TfpgMenuBar.HandleShow;
begin
  PrepareToShow;
  inherited HandleShow;
end;

procedure TfpgMenuBar.HandleMouseMove(x, y: integer; btnstate: word; shiftstate: TShiftState);
var
  newf: integer;
begin
  inherited HandleMouseMove(x, y, btnstate, shiftstate);

  if not MenuFocused then
    Exit; //==>

  newf := CalcMouseCol(x);
  if not VisibleItem(newf).Selectable then
    Exit; //==>

  if newf = FFocusItem then
    Exit; //==>

  //if VisibleItem(newf).SubMenu.Visible then
    //exit;

  FocusItem := newf;
  Repaint;
end;

procedure TfpgMenuBar.HandleLMouseDown(x, y: integer; shiftstate: TShiftState);
var
  newf: integer;
begin
  inherited HandleLMouseDown(x, y, shiftstate);

  if not Focused then
    ActivateMenu;
  //else
  //begin
    //CloseSubmenus;
    //DeActivateMenu;
    //Exit; //==>
  //end;

  newf := CalcMouseCol(x);

  if not VisibleItem(newf).Selectable then
    Exit; //==>

  if newf <> FFocusItem then
  begin
//    DrawColumn(FFocusItem, False);
    FocusItem := newf;
//    DrawColumn(FFocusItem, True);
  end;

  DoSelect;
end;

procedure TfpgMenuBar.HandleKeyPress(var keycode: word;
  var shiftstate: TShiftState; var consumed: boolean);
var
  s: string;
  i: integer;
begin
//  writeln(Classname, '.Keypress');
  s := KeycodeToText(keycode, shiftstate);
//  writeln('s: ', s);
  // handle MenuBar (Alt+?) shortcuts only - for now!
  if (length(s) = 5) and (copy(s, 1, 4) = 'Alt+') then
  begin
    s := KeycodeToText(keycode, []);
    i := SearchItemByAccel(s);
    if i <> -1 then
    begin
      consumed := True;
//      writeln('Selected ', VisibleItem(i).Text);
      FFocusItem := i;
      DoSelect;
    end;
  end;
  inherited HandleKeyPress(keycode, shiftstate, consumed);
end;

procedure TfpgMenuBar.HandlePaint;
var
  n: integer;
  r: TfpgRect;
begin
  Canvas.BeginDraw;
  inherited HandlePaint;
  r.SetRect(0, 0, Width, Height);
  Canvas.Clear(FBackgroundColor);
//  Canvas.DrawButtonFace(r, []);
  // inner bottom line
  Canvas.SetColor(clShadow1);
  Canvas.DrawLine(r.Left, r.Bottom-1, r.Right+1, r.Bottom-1);   // bottom
  // outer bottom line
  Canvas.SetColor(clHilite1);
  Canvas.DrawLine(r.Left, r.Bottom, r.Right+1, r.Bottom);   // bottom

  for n := 1 to VisibleCount do
    DrawColumn(n, n = FocusItem);
  Canvas.EndDraw;
end;

constructor TfpgMenuBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TList.Create;
  FBeforeShow       := nil;
  FFocusItem        := 0;
  FPrevFocusItem    := 0;
  FFocusable        := False;
  FBackgroundColor  := clWindowBackground;
  // calculate the best height based on font
  FHeight := fpgStyle.MenuFont.Height + 6; // 3px margin top and bottom
  
  FLightColor := TfpgColor($f0ece3);  // color at top of menu bar
  FDarkColor  := TfpgColor($beb8a4);  // color at bottom of menu bar
end;

destructor TfpgMenuBar.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TfpgMenuBar.ItemWidth(mi: TfpgMenuItem): integer;
begin
  Result := fpgStyle.MenuFont.TextWidth(mi.Text) + 2*6;
end;

procedure TfpgMenuBar.DrawColumn(col: integer; focus: boolean);
var
  n: integer;
  r: TfpgRect;
  mi: TfpgMenuItem;
begin
  Canvas.BeginDraw;
  r.SetRect(2, 1, 1, fpgStyle.MenuFont.Height+1);

  for n := 1 to VisibleCount do
  begin
    mi := VisibleItem(n);
    r.width := ItemWidth(mi);
    if col = n then
    begin
      if focus and Focused then
      begin
        if MenuFocused then
        begin
          Canvas.SetColor(clSelection);
          Canvas.SetTextColor(clSelectionText);
        end
        else
        begin
//          Canvas.SetColor(clInactiveSel);
          Canvas.SetColor(clShadow1);
          Canvas.SetTextColor(clInactiveSelText);
        end;
      end
      else
      begin
        if mi.Enabled then
        begin
          Canvas.SetColor(BackgroundColor);
          Canvas.SetTextColor(clMenuText);
        end
        else
        begin
          Canvas.SetColor(BackgroundColor);
          Canvas.SetTextColor(clMenuDisabled);
        end;
      end;  { if/else }
      Canvas.FillRectangle(r);
      mi.DrawText(Canvas, r.left+4, r.top+1);
      Canvas.EndDraw(r.Left, r.Top, r.Width, r.Height);
      Exit; //==>
    end;  { if col=n }
    inc(r.Left, ItemWidth(mi));
  end;  { for }
end;

function TfpgMenuBar.CalcMouseCol(x: integer): integer;
var
  w: integer;
  n: integer;
begin
  Result := 1;
  w := 0;
  n := 1;
  while (w <= x) and (n <= VisibleCount) do
  begin
    Result := n;
    inc(w, ItemWidth(VisibleItem(n)));
    inc(n);
  end;
end;

function TfpgMenuBar.GetItemPosX(index: integer): integer;
var
  n: integer;
begin
  Result := 0;
  if index < 1 then
    Exit; //==>
  n := 1;
  while (n <= VisibleCount) and (n < index) do
  begin
    Inc(result, ItemWidth(VisibleItem(n)));
    inc(n);
  end;
end;

procedure TfpgMenuBar.DoSelect;
var
  mi: TfpgMenuItem;
begin
  mi := VisibleItem(FocusItem);
  CloseSubMenus;  // deactivates menubar!

  if mi.SubMenu <> nil then
  begin
    ActivateMenu;
    // showing the submenu
    mi.SubMenu.ShowAt(self, GetItemPosX(FocusItem)+2, fpgStyle.MenuFont.Height+4);
    mi.SubMenu.OpenerPopup := nil;
    mi.SubMenu.OpenerMenuBar := self;
    mi.SubMenu.DontCloseWidget := self;

    uFocusedPopupMenu := mi.SubMenu;
    RePaint;
  end
  else
  begin
    VisibleItem(FocusItem).Click;
    DeActivateMenu;
  end;
end;

procedure TfpgMenuBar.CloseSubmenus;
var
  n: integer;
begin
  // Close all previous popups
  for n := 1 to VisibleCount do
    with VisibleItem(n) do
    begin
      if (SubMenu <> nil) and (SubMenu.HasHandle) then
        SubMenu.Close;
    end;
end;

function TfpgMenuBar.MenuFocused: boolean;
var
  n: integer;
  mi: TfpgMenuItem;
begin
  Result := True;
  for n := 1 to VisibleCount do
  begin
    mi := VisibleItem(n);
    if (mi.SubMenu <> nil) and (mi.SubMenu.HasHandle) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TfpgMenuBar.SearchItemByAccel(s: string): integer;
var
  n: integer;
begin
  Result := -1;
  for n := 1 to VisibleCount do
  begin
    with VisibleItem(n) do
    begin
      {$Note Should UpperCase take note of UTF-8? }
      if Enabled and (UpperCase(s) = UpperCase(GetAccelChar)) then
      begin
        Result := n;
        Exit; //==>
      end;
    end;
  end;
end;

procedure TfpgMenuBar.DeActivateMenu;
begin
  Parent.ActiveWidget := nil;
end;

procedure TfpgMenuBar.ActivateMenu;
begin
  Parent.ActiveWidget := self;
end;

function TfpgMenuBar.AddMenuItem(const AMenuTitle: string; OnClickProc: TNotifyEvent): TfpgMenuItem;
begin
  Result := TfpgMenuItem.Create(self);
  Result.Text       := AMenuTitle;
  Result.HotKeyDef  := '';
  Result.OnClick    := OnClickProc;
  Result.Separator  := False;
end;

{ TfpgPopupMenu }

procedure TfpgPopupMenu.SetBackgroundColor(const AValue: TfpgColor);
begin
  if FBackgroundColor = AValue then Exit; //==>
    Exit;
  FBackgroundColor := AValue;
end;

procedure TfpgPopupMenu.DoSelect;
var
  mi: TfpgMenuItem;
  op: TfpgPopupMenu;
begin
  mi := VisibleItem(FFocusItem);
  if mi.SubMenu <> nil then
  begin
    CloseSubMenus;
    // showing the submenu
    mi.SubMenu.ShowAt(self, Width, GetItemPosY(FFocusItem));
    mi.SubMenu.OpenerPopup := self;
    mi.SubMenu.OpenerMenuBar := OpenerMenuBar;
    uFocusedPopupMenu := mi.SubMenu;
    RePaint;
  end
  else
  begin
    // Close this popup
    Close;
    op := OpenerPopup;
    while op <> nil do
    begin
      if op.HasHandle then
        op.Close;
      op := op.OpenerPopup;
    end;
    VisibleItem(FFocusItem).Click;
  end;  { if/else }

//  if OpenerMenuBar <> nil then
//    OpenerMenuBar.DeActivateMenu;
end;

procedure TfpgPopupMenu.CloseSubmenus;
var
  n: integer;
begin
  // Close all previous popups
  for n := 1 to VisibleCount do
  with VisibleItem(n) do
  begin
    if (SubMenu <> nil) and (SubMenu.HasHandle) then
      SubMenu.Close;
  end;
end;

function TfpgPopupMenu.GetItemPosY(index: integer): integer;
var
  n: integer;
begin
  Result := 2;
  if index < 1 then
    Exit; //==>
  n := 1;
  while (n <= VisibleCount) and (n < index) do
  begin
    Inc(Result, ItemHeight(VisibleItem(n)));
    inc(n);
  end;
end;

procedure TfpgPopupMenu.HandleMouseMove(x, y: integer; btnstate: word; shiftstate: TShiftState);
var
  newf: integer;
begin
  inherited HandleMouseMove(x, y, btnstate, shiftstate);

  if not MenuFocused then
    Exit; //==>

  newf := CalcMouseRow(y);
  if newf < 1 then
    Exit;

  if not VisibleItem(newf).Selectable then
    Exit; //==>

  if newf = FFocusItem then
    Exit; //==>

  FFocusItem := newf;
  Repaint;
end;

procedure TfpgPopupMenu.HandleLMouseDown(x, y: integer; shiftstate: TShiftState);
var
  r: TfpgRect;
begin
  inherited HandleLMouseDown(x, y, shiftstate);

  r.SetRect(0, 0, Width, Height);
  if not PtInRect(r, Point(x, y)) then
  begin
//    writeln('Pointer out of bounds.');
    ClosePopups;
    Exit;
  end;
end;

procedure TfpgPopupMenu.HandleLMouseUp(x, y: integer; shiftstate: TShiftState);
var
  newf: integer;
  mi: TfpgMenuItem;
  r: TfpgRect;
begin
  inherited HandleLMouseUp(x, y, shiftstate);

  newf := CalcMouseRow(y);
  if newf < 1 then
    Exit;

  if not VisibleItem(newf).Selectable then
    Exit; //==>

  if newf <> FFocusItem then
    FFocusItem := newf;

  mi := VisibleItem(FFocusItem);
  if (mi <> nil) and (not MenuFocused) and (mi.SubMenu <> nil)
      and mi.SubMenu.HasHandle then
    mi.SubMenu.Close
  else
    DoSelect;
end;

procedure TfpgPopupMenu.HandleKeyPress(var keycode: word; var shiftstate: TShiftState; var consumed: boolean);
var
  oldf: integer;
  i: integer;
  s: string;
  op: TfpgPopupMenu;
  trycnt: integer;

  procedure FollowFocus;
  begin
    if oldf <> FFocusItem then
    begin
      Repaint;
    end;
  end;

begin
  inherited HandleKeyPress(keycode, shiftstate, consumed);

  oldf := FFocusItem;

  consumed := true;
  case keycode of
    keyUp:
           begin // up
             trycnt := 2;
             i := FFocusItem-1;
             repeat
               while (i >= 1) and not VisibleItem(i).Selectable do dec(i);

               if i >= 1 then break;

               i := VisibleCount;
               dec(trycnt);
             until trycnt > 0;

             if i >= 1 then FFocusItem := i;
           end;
    keyDown:
           begin // down

             trycnt := 2;
             i := FFocusItem+1;
             repeat
               while (i <= VisibleCount) and not VisibleItem(i).Selectable do inc(i);

               if i <= VisibleCount then break;

               i := 1;
               dec(trycnt);
             until trycnt > 0;

             if i <= VisibleCount then FFocusItem := i;

           end;
    keyReturn:
           begin
             DoSelect;
           end;

    keyLeft:
           begin
             if OpenerMenubar <> nil then OpenerMenubar.HandleKeyPress(keycode, shiftstate, consumed);
           end;

    keyRight:
           begin
             if OpenerMenubar <> nil then OpenerMenubar.HandleKeyPress(keycode, shiftstate, consumed);
             // VisibleItem(FFocusItem).SubMenu <> nil then DoSelect;
           end;

    keyBackSpace:
           begin
             //if self.OpenerPopup <> nil then
             Close;
           end;

    keyEscape:
           begin
             Close;
             op := OpenerPopup;
             while op <> nil do
             begin
               op.Close;
               op := op.OpenerPopup;
             end;
           end;
  else
    consumed := false;
  end;

  FollowFocus;

  if (not consumed) and ((keycode and $8000) <> $8000) then
  begin
    // normal char
    s := chr(keycode and $00FF) + chr((keycode and $FF00) shr 8);
    i := SearchItemByAccel(s);
    if i > 0 then
    begin
      FFocusItem := i;
      FollowFocus;
      Consumed := true;
      DoSelect;
    end;
  end;
end;

procedure TfpgPopupMenu.HandlePaint;
var
  n: integer;
begin
  Canvas.BeginDraw;
//  inherited HandlePaint;
  Canvas.Clear(FBackgroundColor);
  Canvas.SetColor(clWidgetFrame);
  Canvas.DrawRectangle(0, 0, Width, Height);  // black rectangle border
  Canvas.DrawButtonFace(1, 1, Width-1, Height-1, []);  // 3d rectangle inside black border

  for n := 1 to VisibleCount do
    DrawRow(n, n = FFocusItem);

  Canvas.EndDraw;
end;

procedure TfpgPopupMenu.HandleShow;
begin
  PrepareToShow;
  inherited HandleShow;
end;

function TfpgPopupMenu.VisibleCount: integer;
begin
  Result := FItems.Count;
end;

function TfpgPopupMenu.VisibleItem(ind: integer): TfpgMenuItem;
begin
  if (ind < 1) or (ind > FItems.Count) then
    Result := nil
  else
    Result := TfpgMenuItem(FItems.Items[ind-1]);
end;

procedure TfpgPopupMenu.DrawItem(mi: TfpgMenuItem; rect: TfpgRect);
var
  s: string;
  x: integer;
  img: TfpgImage;
begin
  if mi.Separator then
  begin
    Canvas.SetColor(clMenuText);
    Canvas.DrawLine(rect.Left, rect.Top+2, rect.Right+1, rect.Top+2);
  end
  else
  begin
    x := rect.Left + FSymbolWidth + FTextMargin;

    mi.DrawText(Canvas, x, rect.top);

    if mi.HotKeyDef <> '' then
    begin
      s := mi.HotKeyDef;
      Canvas.DrawString(rect.Right-FMenuFont.TextWidth(s)-FTextMargin, rect.Top, s);
    end;

    if mi.SubMenu <> nil then
    begin
      canvas.SetColor(Canvas.TextColor);
      x := (rect.height div 2) - 3;
      img := fpgImages.GetImage('sys.sb.right');
      Canvas.DrawImage(rect.right-x-2, rect.Top + ((rect.Height-img.Height) div 2), img);
//      canvas.FillTriangle(rect.right-x-2, rect.top+2,
//                          rect.right-2, rect.top+2+x,
//                          rect.right-x-2, rect.top+2+2*x);
    end;
  end;
end;

procedure TfpgPopupMenu.DrawRow(line: integer; focus: boolean);
var
  n: integer;
  r: TfpgRect;
  mi: TfpgMenuItem;
begin
  Canvas.BeginDraw;
  r.SetRect(FMargin, FMargin, FWidth-(2*FMargin), FHeight-(2*FMargin));

  for n := 1 to VisibleCount do
  begin
    mi := VisibleItem(n);

    r.height := ItemHeight(mi);

    if line = n then
    begin
      if focus and (not mi.Separator) then
      begin
        if MenuFocused then
        begin
          Canvas.SetColor(clSelection);
          Canvas.SetTextColor(clSelectionText);
        end
        else
        begin
          Canvas.SetColor(clShadow1);
          Canvas.SetTextColor(clInactiveSelText);
        end;
      end
      else
      begin
        if mi.Enabled then
        begin
          Canvas.SetColor(BackgroundColor);
          Canvas.SetTextColor(clMenuText);
        end
        else
        begin
          Canvas.SetColor(BackgroundColor);
          Canvas.SetTextColor(clMenuDisabled);
        end;
      end;
      Canvas.FillRectangle(r);
      DrawItem(mi, r);
      Canvas.EndDraw(r.Left, r.Top, r.Width, r.Height);
      Exit; //==>
    end;
    inc(r.Top, ItemHeight(mi) );
  end;  { for }
end;

function TfpgPopupMenu.ItemHeight(mi: TfpgMenuItem): integer;
begin
  if mi.Separator then
    Result := 5
  else
    Result := FMenuFont.Height + 2;
end;

function TfpgPopupMenu.MenuFocused: boolean;
begin
  Result := (uFocusedPopupMenu = self);
end;

function TfpgPopupMenu.SearchItemByAccel(s: string): integer;
var
  n: integer;
begin
  result := -1;
  for n := 1 to VisibleCount do
  begin
    with VisibleItem(n) do
    begin
      {$Note Do we need to use UTF-8 upper case? }
      if Enabled and (UpperCase(s) = UpperCase(GetAccelChar)) then
      begin
        result := n;
        Exit; //==>
      end;
    end;
  end;
end;

procedure TfpgPopupMenu.HandleMouseExit;
begin
  inherited HandleMouseExit;
  FFocusItem := 0;
  Repaint;
end;

// Collecting visible items and measuring sizes
procedure TfpgPopupMenu.PrepareToShow;
var
  n: integer;
  h: integer;
  tw: integer;
  hkw: integer;
  x: integer;
  mi: TfpgMenuItem;
begin
  if Assigned(FBeforeShow) then
    FBeforeShow(self);

  // Collecting visible items
  FItems.Count := 0;

  for n := 0 to ComponentCount-1 do
  begin
    if Components[n] is TfpgMenuItem then
    begin
      mi := TfpgMenuItem(Components[n]);
      if mi.Visible then
        FItems.Add(mi);
    end;
  end;

  // Measuring sizes
  h             := 0;
  tw            := 0;
  hkw           := 0;
  FSymbolWidth  := 0;
  for n := 1 to VisibleCount do
  begin
    mi  := VisibleItem(n);
    x   := ItemHeight(mi);
    inc(h, x);
    x := FMenuFont.TextWidth(mi.Text);
    if tw < x then
      tw := x;

    if mi.SubMenu <> nil then
      x := FMenuFont.Height
    else
      x := FMenuFont.TextWidth(mi.HotKeyDef);
    if hkw < x then
      hkw := x;
  end;

  if hkw > 0 then
    hkw := hkw + 5;

  FHeight := FMargin*2 + h;
  FWidth  := (FMargin+FTextMargin)*2 + FSymbolWidth + tw + hkw;

  uFocusedPopupMenu := self;
end;

function TfpgPopupMenu.CalcMouseRow(y: integer): integer;
var
  h: integer;
  n: integer;
begin
  h := 2;
  n := 0;
  Result := n;

  // sanity check
  if y < 1 then
    Exit
  else
    n := 1;
    
  while (h <= y) and (n <= VisibleCount) do
  begin
    Result := n;
    inc(h, ItemHeight(VisibleItem(n)));
    inc(n);
  end;
end;

constructor TfpgPopupMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMargin     := 3;
  FTextMargin := 3;
  FItems      := TList.Create;
  FBackgroundColor := clWindowBackground;
  // fonts
  FMenuFont         := fpgStyle.MenuFont;
  FMenuAccelFont    := fpgStyle.MenuAccelFont;
  FMenuDisabledFont := fpgStyle.MenuDisabledFont;
  FSymbolWidth      := FMenuFont.Height+2;

  FBeforeShow   := nil;
  FFocusItem    := 0;
  OpenerPopup   := nil;
  OpenerMenubar := nil;
end;

destructor TfpgPopupMenu.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

{$Note See if we can move this to HandleHide + not make Close virtual! }
procedure TfpgPopupMenu.Close;
var
  n: integer;
  mi: TfpgMenuItem;
begin
  for n := 0 to FItems.Count-1 do
  begin
    mi := TfpgMenuItem(FItems[n]);
    if mi.SubMenu <> nil then
    begin
      if mi.SubMenu.HasHandle then
        mi.SubMenu.Close;
    end;
  end;
  inherited Close;
  uFocusedPopupMenu := OpenerPopup;
  if (uFocusedPopupMenu <> nil) and uFocusedPopupMenu.HasHandle then
    uFocusedPopupMenu.RePaint;

  if (OpenerMenuBar <> nil) and OpenerMenuBar.HasHandle then
  begin
    if (OpenerPopup = nil) or not OpenerPopup.HasHandle then
    begin
      OpenerMenuBar.DeActivateMenu;
      //OpenerMenuBar.Repaint;
    end;
    //else
    //OpenerMenuBar.RePaint;
  end;
end;

function TfpgPopupMenu.AddMenuItem(const AMenuName: string;
    const hotkeydef: string; HandlerProc: TNotifyEvent): TfpgMenuItem;
begin
  result := TfpgMenuItem.Create(self);
  if AMenuName <> '-' then
  begin
    result.Text := AMenuName;
    result.hotkeydef := hotkeydef;
    result.OnClick := HandlerProc;
  end
  else
  begin
    result.Separator := true;
  end;
end;

function TfpgPopupMenu.MenuItemByName(const AMenuName: string): TfpgMenuItem;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to ComponentCount-1 do
  begin
    if Components[i] is TfpgMenuItem then
      if SameText(TfpgMenuItem(Components[i]).Text, AMenuName) then
      begin
        Result := TfpgMenuItem(Components[i]);
        Exit; //==>
      end;
  end;
end;

initialization
  uFocusedPopupMenu := nil;
  
end.

