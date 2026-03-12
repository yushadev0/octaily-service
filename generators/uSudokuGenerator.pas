unit uSudokuGenerator;

interface

uses
  System.SysUtils, System.JSON, uBaseGenerator, System.Math;

type
  TOctailySudokuGenerator = class(TOctailyBaseGenerator)
  private
    FGrid: array[0..8, 0..8] of Integer;       // Kullanıcıya gönderilecek (Boşluklu)
    FSolution: array[0..8, 0..8] of Integer;   // Gizli çözüm anahtarı

    function IsSafe(Row, Col, Num: Integer; const AGrid: array of array of Integer): Boolean; overload;
    function IsSafe(Row, Col, Num: Integer): Boolean; overload; // FSolution üzerinde kontrol
    function Solve(Row, Col: Integer): Boolean;
    procedure RemoveDigits(Count: Integer);
  public
    constructor Create(AGameName: string); reintroduce;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;
  end;

implementation

{ TOctailySudokuGenerator }

constructor TOctailySudokuGenerator.Create(AGameName: string);
begin
  inherited Create(AGameName);
end;

function TOctailySudokuGenerator.IsSafe(Row, Col, Num: Integer): Boolean;
var
  I, J, StartRow, StartCol: Integer;
begin
  // Satır ve Sütun kontrolü
  for I := 0 to 8 do
    if (FSolution[Row, I] = Num) or (FSolution[I, Col] = Num) then Exit(False);

  // 3x3 Blok kontrolü
  StartRow := Row - Row mod 3;
  StartCol := Col - Col mod 3;
  for I := 0 to 2 do
    for J := 0 to 2 do
      if FSolution[I + StartRow, J + StartCol] = Num then Exit(False);

  Result := True;
end;

function TOctailySudokuGenerator.Solve(Row, Col: Integer): Boolean;
var
  Num: Integer;
begin
  // Tablo bitti mi?
  if (Row = 8) and (Col = 9) then Exit(True);
  if Col = 9 then begin Row := Row + 1; Col := 0; end;
  if FSolution[Row, Col] <> 0 then Exit(Solve(Row, Col + 1));

  // 1-9 arası rakamları dene
  for Num := 1 to 9 do
  begin
    if IsSafe(Row, Col, Num) then
    begin
      FSolution[Row, Col] := Num;
      if Solve(Row, Col + 1) then Exit(True);
    end;
    FSolution[Row, Col] := 0; // Backtrack
  end;
  Result := False;
end;

procedure TOctailySudokuGenerator.GenerateDailyPuzzle;
var
  I, J, R: Integer;
begin
  Randomize;
  // 1. Tabloyu temizle
  for I := 0 to 8 do
    for J := 0 to 8 do FSolution[I, J] := 0;

  // 2. İlk satıra rastgelelik kat (Her gün farklı bir tablo için)
  for I := 0 to 8 do
  begin
    R := Random(9) + 1;
    // Basit bir kontrolle ilk satırı dolduruyoruz
    FSolution[0, I] := R;
  end;

  // 3. Geçerli bir tam tablo oluştur
  Solve(0, 0);

  // 4. Çözümü FGrid'e kopyala ve içinden rakam sil
  for I := 0 to 8 do
    for J := 0 to 8 do FGrid[I, J] := FSolution[I, J];

  // Zorluk: 45 hücreyi boşalt (Orta/Zor seviye)
  RemoveDigits(45);
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
    for C := 0 to 8 do RowArr.Add(FGrid[R, C]);
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

    // Kullanıcının gönderdiği 9x9 tabloyu çözümle karşılaştır
    for R := 0 to 8 do
    begin
      RowArr := JSONGuess.Items[R] as TJSONArray;
      for C := 0 to 8 do
      begin
        Val := RowArr.Items[C].Value.ToInteger;
        if Val <> FSolution[R, C] then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('error', Format('Hata: Satır %d, Sütun %d yanlış!', [R+1, C+1]));
          Exit;
        end;
      end;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Tebrikler, Sudoku tamamlandı!');
  except
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Kontrol sırasında hata oluştu');
  end;
end;

end.
