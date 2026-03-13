unit uSudokuGenerator;

interface

uses
  System.SysUtils, System.JSON, uBaseGenerator, System.Math;

type
  TOctailySudokuGenerator = class(TOctailyBaseGenerator)
  private
    FGrid: array [0 .. 8, 0 .. 8] of Integer;
    // Kullanıcıya gönderilecek (Boşluklu)
    FSolution: array [0 .. 8, 0 .. 8] of Integer; // Gizli çözüm anahtarı

    // Fazlalık olan overload kaldırıldı, sadece gerekli olan kaldı
    function IsSafe(Row, Col, Num: Integer): Boolean;
    function Solve(Row, Col: Integer): Boolean;
    procedure RemoveDigits(Count: Integer);

  public
    constructor Create(AGameName: string); reintroduce;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;
    function GetDebugAnswer: string; override;
  end;

implementation

{ TOctailySudokuGenerator }

constructor TOctailySudokuGenerator.Create(AGameName: string);
begin
  inherited Create(AGameName);
end;

function TOctailySudokuGenerator.GetDebugAnswer: string;
var
  Row, Col: Integer;
begin
  // Sudoku tahtasının Memo'da alt satırdan başlaması için ilk satır başını ekleyelim
  Result := sLineBreak;

  for Row := 0 to 8 do
  begin
    for Col := 0 to 8 do
    begin
      // Rakamı string'e çevir ve arasına bir boşluk koy
      Result := Result + IntToStr(FSolution[Row, Col]) + ' ';

      // Şık bir görünüm için her 3 sütunda bir dikey çizgi (|) koyabilirsin
      if (Col = 2) or (Col = 5) then
        Result := Result + '| ';
    end;

    // Satır bittiğinde bir alt satıra geç
    Result := Result + sLineBreak;

    // Her 3 satırda bir yatay ayırıcı çizgi ekleyelim
    if (Row = 2) or (Row = 5) then
      Result := Result + '-----------------------' + sLineBreak;
  end;
end;

function TOctailySudokuGenerator.IsSafe(Row, Col, Num: Integer): Boolean;
var
  I, J, StartRow, StartCol: Integer;
begin
  // Satır ve Sütun kontrolü
  for I := 0 to 8 do
    if (FSolution[Row, I] = Num) or (FSolution[I, Col] = Num) then
      Exit(False);

  // 3x3 Blok kontrolü
  StartRow := (Row div 3) * 3;
  StartCol := (Col div 3) * 3;
  for I := 0 to 2 do
    for J := 0 to 2 do
      if FSolution[StartRow + I, StartCol + J] = Num then
        Exit(False);

  Result := True;
end;

function TOctailySudokuGenerator.Solve(Row, Col: Integer): Boolean;
var
  Num: Integer;
begin
  if (Row = 8) and (Col = 9) then
    Exit(True);
  if Col = 9 then
  begin
    Row := Row + 1;
    Col := 0;
  end;

  if FSolution[Row, Col] <> 0 then
    Exit(Solve(Row, Col + 1));

  for Num := 1 to 9 do
  begin
    if IsSafe(Row, Col, Num) then
    begin
      FSolution[Row, Col] := Num;
      if Solve(Row, Col + 1) then
        Exit(True);
    end;
    FSolution[Row, Col] := 0; // Backtrack
  end;
  Result := False;
end;

procedure TOctailySudokuGenerator.GenerateDailyPuzzle;
var
  I, J, R, TryCount: Integer;
begin
  Randomize;
  // 1. Tabloyu temizle
  for I := 0 to 8 do
    for J := 0 to 8 do
      FSolution[I, J] := 0;

  // 2. İlk satırı kurallara uygun şekilde rastgele doldur
  TryCount := 0;
  I := 0;
  while (I < 9) and (TryCount < 100) do
  begin
    R := Random(9) + 1;
    if IsSafe(0, I, R) then
    begin
      FSolution[0, I] := R;
      Inc(I);
    end;
    Inc(TryCount);
  end;

  // 3. Geri kalan tabloyu doldur
  Solve(0, 0);

  // 4. Çözümü kopyala ve içinden rakam sil
  for I := 0 to 8 do
    for J := 0 to 8 do
      FGrid[I, J] := FSolution[I, J];

  RemoveDigits(45); // Orta zorluk
  FGameDate := Date;
end;

procedure TOctailySudokuGenerator.RemoveDigits(Count: Integer);
var
  R, C: Integer;
begin
  while Count > 0 do
  begin
    R := Random(9);
    C := Random(9);
    if FGrid[R, C] <> 0 then
    begin
      FGrid[R, C] := 0;
      Dec(Count);
    end;
  end;
end;

function TOctailySudokuGenerator.GetDailyPuzzleJSON: TJSONObject;
var
  GridArr, RowArr: TJSONArray;
  R, C: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);

  GridArr := TJSONArray.Create;
  for R := 0 to 8 do
  begin
    RowArr := TJSONArray.Create;
    for C := 0 to 8 do
      RowArr.Add(FGrid[R, C]);
    GridArr.AddElement(RowArr);
  end;
  Result.AddPair('grid', GridArr);
end;

function TOctailySudokuGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  JSONGuess, RowArr: TJSONArray;
  R, C, Val: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('game', FGameName);

  try
    JSONGuess := TJSONObject.ParseJSONValue(AGuess) as TJSONArray;
    if (not Assigned(JSONGuess)) or (JSONGuess.Count <> 9) then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', 'Geçersiz 9x9 tablo formatı');
      Exit;
    end;

    for R := 0 to 8 do
    begin
      RowArr := JSONGuess.Items[R] as TJSONArray;
      for C := 0 to 8 do
      begin
        // JSON parsing kısmını daha güvenli hale getirdik
        Val := RowArr.Items[C].GetValue<Integer>;
        if Val <> FSolution[R, C] then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('error', Format('Hata: Satır %d, Sütun %d yanlış!',
            [R + 1, C + 1]));
          Exit;
        end;
      end;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Tebrikler, Sudoku tamamlandı!');
  except
    on E: Exception do
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', 'Kontrol hatası: ' + E.Message);
    end;
  end;
end;

end.
