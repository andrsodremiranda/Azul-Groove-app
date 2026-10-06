; Animação do instalador:
;  - boas-vindas e conclusão: barras de equalizador dançando no painel da esquerda
;  - instalando: faixa animada com barras, texto "Instalando..." e barra de progresso real
; Incluído por AzulGroove.iss.
; Se der qualquer erro de compilação neste arquivo, apague a linha
;   #include "installer-animation.iss"
; no fim do AzulGroove.iss — o instalador continua funcionando, só sem a animação.

[Code]
function SetTimer(hWnd, nIDEvent, uElapse, lpTimerFunc: LongWord): LongWord;
  external 'SetTimer@user32.dll stdcall';
function KillTimer(hWnd, uIDEvent: LongWord): Boolean;
  external 'KillTimer@user32.dll stdcall';

var
  AnimTimer: LongWord;
  AnimTick: Integer;
  BaseBmp: TBitmap;
  InstallBanner: TBitmapImage;

procedure DrawBars(Img: TBitmapImage);
var
  W, H, i, bw, gap, total, x0, left, v, bh, cy, maxH: Integer;
  C: TCanvas;
  R: TRect;
begin
  if (BaseBmp = nil) or (Img = nil) then Exit;
  W := BaseBmp.Width;
  H := BaseBmp.Height;
  C := Img.Bitmap.Canvas;
  R.Left := 0; R.Top := 0; R.Right := W; R.Bottom := H;
  C.CopyRect(R, BaseBmp.Canvas, R);    { repõe o fundo }

  bw := W * 6 div 100;                 { largura de cada barra }
  gap := W * 3 div 100;
  total := 7 * bw + 6 * gap;
  x0 := (W - total) div 2;
  cy := H * 35 div 100;                { centro do "visor" }
  maxH := H * 24 div 100;              { altura máxima das barras }

  C.Pen.Color := $FFFFFF;
  for i := 0 to 6 do
  begin
    v := (AnimTick * 2 + i * 7) mod 40;   { onda triangular 0..20 }
    if v > 20 then v := 40 - v;
    bh := maxH * (20 + v * 4) div 100;
    left := x0 + i * (bw + gap);
    if (i mod 2) = 0 then
      C.Brush.Color := $FFFFFF
    else
      C.Brush.Color := $FFE6C8;           { azul bem clarinho (BGR) }
    C.Pen.Color := C.Brush.Color;
    C.RoundRect(left, cy - bh div 2, left + bw, cy + bh div 2, bw, bw);
  end;
  Img.Invalidate;
end;

{ Faixa animada da página "Instalando" }
procedure DrawInstall;
var
  W, H, i, u, bw, gap, total, x0, left, v, bh, cy, maxH: Integer;
  pct, mx, textX, barX, barY, barW, barH, fillW: Integer;
  C: TCanvas;
begin
  if InstallBanner = nil then Exit;
  W := InstallBanner.Bitmap.Width;
  H := InstallBanner.Bitmap.Height;
  C := InstallBanner.Bitmap.Canvas;

  { fundo azul-roxo (#5865F2 em BGR) }
  C.Brush.Color := $F26558;
  C.Pen.Color := $F26558;
  C.Rectangle(0, 0, W, H);

  { barras de equalizador }
  u := H div 10;
  bw := u;
  gap := u * 6 div 10;
  total := 5 * bw + 4 * gap;
  x0 := H * 3 div 10;
  cy := H div 2;
  maxH := H * 6 div 10;
  for i := 0 to 4 do
  begin
    v := (AnimTick * 2 + i * 8) mod 40;
    if v > 20 then v := 40 - v;
    bh := maxH * (20 + v * 4) div 100;
    left := x0 + i * (bw + gap);
    if (i mod 2) = 0 then C.Brush.Color := $FFFFFF else C.Brush.Color := $FFE6C8;
    C.Pen.Color := C.Brush.Color;
    C.RoundRect(left, cy - bh div 2, left + bw, cy + bh div 2, bw, bw);
  end;

  { progresso real da instalação }
  pct := 0;
  mx := WizardForm.ProgressGauge.Max - WizardForm.ProgressGauge.Min;
  if mx > 0 then
    pct := (WizardForm.ProgressGauge.Position - WizardForm.ProgressGauge.Min) * 100 div mx;
  if pct > 100 then pct := 100;

  { texto }
  textX := x0 + total + u * 3;
  C.Brush.Color := $F26558;
  C.Font.Name := 'Segoe UI';
  C.Font.Size := 11;
  C.Font.Color := $FFFFFF;
  C.TextOut(textX, H * 2 div 10,
    'Instalando o Azul Groove' + Copy('...', 1, (AnimTick div 4) mod 4) + '  ' + IntToStr(pct) + '%');

  { barra de progresso }
  barX := textX;
  barY := H * 62 div 100;
  barW := W - barX - H * 3 div 10;
  barH := H * 12 div 100;
  if barH < 6 then barH := 6;
  C.Brush.Color := $BE463C;
  C.Pen.Color := $BE463C;
  C.RoundRect(barX, barY, barX + barW, barY + barH, barH, barH);
  fillW := barW * pct div 100;
  if (pct > 0) and (fillW < barH) then fillW := barH;
  if fillW > 0 then
  begin
    C.Brush.Color := $FFFFFF;
    C.Pen.Color := $FFFFFF;
    C.RoundRect(barX, barY, barX + fillW, barY + barH, barH, barH);
  end;

  InstallBanner.Invalidate;
end;

procedure AnimProc(H, Msg, Id, Time: LongWord);
begin
  AnimTick := AnimTick + 1;
  try
    if WizardForm.CurPageID = wpWelcome then
      DrawBars(WizardForm.WizardBitmapImage)
    else if WizardForm.CurPageID = wpInstalling then
      DrawInstall
    else if WizardForm.CurPageID = wpFinished then
      DrawBars(WizardForm.WizardBitmapImage2);
  except
    { nunca deixa a animação derrubar o instalador }
  end;
end;

procedure InitializeWizard;
begin
  BaseBmp := TBitmap.Create;
  BaseBmp.Assign(WizardForm.WizardBitmapImage.Bitmap);

  { faixa animada na página "Instalando" }
  try
    InstallBanner := TBitmapImage.Create(WizardForm);
    InstallBanner.Parent := WizardForm.InstallingPage;
    InstallBanner.Left := WizardForm.ProgressGauge.Left;
    InstallBanner.Top := WizardForm.FilenameLabel.Top + WizardForm.FilenameLabel.Height + ScaleY(16);
    InstallBanner.Width := WizardForm.ProgressGauge.Width;
    InstallBanner.Height := ScaleY(96);
    InstallBanner.Bitmap.Width := InstallBanner.Width;
    InstallBanner.Bitmap.Height := InstallBanner.Height;
  except
    InstallBanner := nil;
  end;
  AnimTimer := SetTimer(0, 0, 70, CreateCallback(@AnimProc));
end;

procedure DeinitializeSetup;
begin
  if AnimTimer <> 0 then
    KillTimer(0, AnimTimer);
  AnimTimer := 0;
end;
