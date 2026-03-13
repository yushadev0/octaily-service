unit uSudokuGenerator;

interface

uses
  System.SysUtils, System.JSON, uBaseGenerator, System.Math;

type
  TSudokuGrid = array[0..8, 0..8] of Integer;

  TOctailySudokuGenerator = class(TOctailyBaseGenerator)
  private
    FGrid: TSudokuGrid;     // Kullanıcıya gönderilecek (Boşluklu)
    FSolution: TSudokuGrid; // Gizli çözüm anahtarı

    // Yardımcı fonksiyonlar
    function IsSafeInGrid(const AGrid: TSudokuGrid; Row, Col, Num: Integer): Boolean;
    function GenerateSolvedGrid(Row, Col: Integer): Boolean;
    function CountSolutions(var AGrid: TSudokuGrid; Row, Col: Integer): Integer;
    procedure RemoveDigits(TargetEmptyCount: Integer);

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
  Result := sLineBreak;
  for Row := 0 to 8 do
  begin
    for Col := 0 to 8 do
    begin
      Result := Result + IntToStr(FSolution[Row, Col]) + ' ';
      if (Col = 2) or (Col = 5) then
        Result := Result + '| ';
    end;
    Result := Result + sLineBreak;
    if (Row = 2) or (Row = 5) then
      Result := Result + '-----------------------' + sLineBreak;
  end;
end;

// Belirtilen gride rakam koymak güvenli mi? (Satır, Sütun, 3x3 Blok kontrolü)
function TOctailySudokuGenerator.IsSafeInGrid(const AGrid: TSudokuGrid; Row, Col, Num: Integer): Boolean;
var
  I, J, StartRow, StartCol: Integer;
begin
  for I := 0 to 8 do
    if (AGrid[Row, I] = Num) or (AGrid[I, Col] = Num) then
      Exit(False);

  StartRow := (Row div 3) * 3;
  StartCol := (Col div 3) * 3;
  for I := 0 to 2 do
    for J := 0 to 2 do
      if AGrid[StartRow + I, StartCol + J] = Num then
        Exit(False);

  Result := True;
end;

// Karıştırılmış (Shuffled) Backtracking ile %100 rastgele ve doğru bir tahta üretir
function TOctailySudokuGenerator.GenerateSolvedGrid(Row, Col: Integer): Boolean;
var
  I, J, Temp, NextRow, NextCol: Integer;
  Nums: array[0..8] of Integer;
begin
  if Row = 9 then Exit(True); // Tüm satırlar bitti, başarı!

  NextRow := Row;
  NextCol := Col + 1;
  if NextCol = 9 then
  begin
    NextRow := Row + 1;
    NextCol := 0;
  end;

  if FSolution[Row, Col] <> 0 then
    Exit(GenerateSolvedGrid(NextRow, NextCol));

  // 1'den 9'a kadar rakamları sırayla değil, karıştırarak dene!
  for I := 0 to 8 do Nums[I] := I + 1;
  for I := 8 downto 1 do
  begin
    J := Random(I + 1);
    Temp := Nums[I];
    Nums[I] := Nums[J];
    Nums[J] := Temp;
  end;

  for I := 0 to 8 do
  begin
    if IsSafeInGrid(FSolution, Row, Col, Nums[I]) then
    begin
      FSolution[Row, Col] := Nums[I];
      if GenerateSolvedGrid(NextRow, NextCol) then Exit(True);
      FSolution[Row, Col] := 0; // Backtrack
    end;
  end;
  Result := False;
end;

// Bu fonksiyon tahtanın benzersiz (tek) bir çözümü olup olmadığını sayar
function TOctailySudokuGenerator.CountSolutions(var AGrid: TSudokuGrid; Row, Col: Integer): Integer;
var
  Num, NextRow, NextCol: Integer;
begin
  if Row = 9 then Exit(1); // 1 çözüm bulundu

  NextRow := Row;
  NextCol := Col + 1;
  if NextCol = 9 then
  begin
    NextRow := Row + 1;
    NextCol := 0;
  end;

  if AGrid[Row, Col] <> 0 then
    Exit(CountSolutions(AGrid, NextRow, NextCol));

  Result := 0;
  for Num := 1 to 9 do
  begin
    if IsSafeInGrid(AGrid, Row, Col, Num) then
    begin
      AGrid[Row, Col] := Num;
      Result := Result + CountSolutions(AGrid, NextRow, NextCol);
      AGrid[Row, Col] := 0; // Backtrack

      // Eğer zaten 1'den fazla çözüm bulduysak, zaman kaybetme, çık! (Matematiksel olarak hatalı Sudoku)
      if Result > 1 then Exit(Result);
    end;
  end;
end;

// Matematiksel kuralları bozmadan hücreleri gizler
procedure TOctailySudokuGenerator.RemoveDigits(TargetEmptyCount: Integer);
var
  Attempts, R, C, Backup, EmptyCount: Integer;
begin
  Attempts := 0;
  EmptyCount := 0;

  // Tahtayı bozmadan hedef boşluk sayısına ulaşmaya çalış (Max 200 deneme)
  while (EmptyCount < TargetEmptyCount) and (Attempts < 200) do
  begin
    R := Random(9);
    C := Random(9);

    if FGrid[R, C] <> 0 then
    begin
      Backup := FGrid[R, C];
      FGrid[R, C] := 0; // Silmeyi dene

      // Sildiğimizde bulmacanın ÇİFT çözümü oluyorsa, silmekten vazgeç, sayıyı geri koy!
      if CountSolutions(FGrid, 0, 0) <> 1 then
        FGrid[R, C] := Backup
      else
        Inc(EmptyCount); // Güvenle silindi
    end;
    Inc(Attempts);
  end;
end;

procedure TOctailySudokuGenerator.GenerateDailyPuzzle;
var
  R, C: Integer;
begin
  Randomize;

  // 1. Tabloları temizle
  for R := 0 to 8 do
    for C := 0 to 8 do
    begin
      FSolution[R, C] := 0;
      FGrid[R, C] := 0;
    end;

  // 2. Gizli çözüm anahtarını (%100 dolu ve doğru) rastgele üret
  GenerateSolvedGrid(0, 0);

  // 3. Kullanıcıya gidecek gridi kopyala
  for R := 0 to 8 do
    for C := 0 to 8 do
      FGrid[R, C] := FSolution[R, C];

  // 4. Kaliteli bir Sudoku elde etmek için 45 ila 50 civarı hücreyi zekice gizle
  RemoveDigits(50); // Orta/Zor Seviye (Tekil çözüm garantili)

  FGameDate := Date;
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
        Val := RowArr.Items[C].GetValue<Integer>;
        if Val <> FSolution[R, C] then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('error', Format('Hata: Satır %d, Sütun %d yanlış!', [R + 1, C + 1]));
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
