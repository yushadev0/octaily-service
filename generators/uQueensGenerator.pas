unit uQueensGenerator;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, uBaseGenerator;

type
  TSetOfByte = set of 0 .. 255; // Bunu ekle

  TPoint = record
    X, Y: Integer;
  end;

  TOctailyQueensGenerator = class(TOctailyBaseGenerator)
  private
    FGridSize: Integer;
    FSolution: TArray<TPoint>; // Doğru kraliçe yerleri
    FRegions: TArray<TArray<Integer>>; // Her hücrenin bölge ID'si
    procedure ClearGrid;
    function IsValidPlacement(const APoints: TArray<TPoint>): Boolean;
    function PlaceQueensBacktracking(Row: Integer): Boolean;
  public
    constructor Create(AGameName: string; ASize: Integer = 8); reintroduce;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;
  end;

implementation

{ TOctailyQueensGenerator }

constructor TOctailyQueensGenerator.Create(AGameName: string; ASize: Integer);
begin
  inherited Create(AGameName);
  FGridSize := ASize;
end;

procedure TOctailyQueensGenerator.ClearGrid;
begin
  SetLength(FRegions, FGridSize, FGridSize);
  SetLength(FSolution, 0);
end;

function TOctailyQueensGenerator.IsValidPlacement(const APoints
  : TArray<TPoint>): Boolean;
var
  I, J: Integer;
  Rows, Cols, Regions: TSetOfByte;
  // Set kullanarak çakışmaları hızlıca bulacağız
  P1, P2: TPoint;
begin
  Result := False;

  // 1. Kraliçe sayısı doğru mu? (N x N tahtada N kraliçe olmalı)
  if Length(APoints) <> FGridSize then
    Exit;

  // Kontrol için yardımcı kümeleri (set) hazırlayalım (Delphi'de küme kullanımı çok hızlıdır)
  // Not: Eğer hata alırsan implementation'ın en üstüne 'type TSetOfByte = set of 0..255;' ekleyebilirsin.

  for I := 0 to High(APoints) do
  begin
    P1 := APoints[I];

    // Sınır kontrolü
    if (P1.X < 0) or (P1.X >= FGridSize) or (P1.Y < 0) or (P1.Y >= FGridSize)
    then
      Exit;

    for J := I + 1 to High(APoints) do
    begin
      P2 := APoints[J];

      // 2. Aynı SATIR kontrolü
      if P1.X = P2.X then
        Exit;

      // 3. Aynı SÜTUN kontrolü
      if P1.Y = P2.Y then
        Exit;

      // 4. Aynı BÖLGE (Region) kontrolü
      if FRegions[P1.X, P1.Y] = FRegions[P2.X, P2.Y] then
        Exit;

      // 5. DOKUNMA (Adjacency) kontrolü
      // Kraliçeler çapraz dahil birbirine değmemeli (Mesafe her yönden > 1 olmalı)
      if (Abs(P1.X - P2.X) <= 1) and (Abs(P1.Y - P2.Y) <= 1) then
        Exit;
    end;
  end;

  Result := True; // Tüm testlerden geçti!
end;

function TOctailyQueensGenerator.PlaceQueensBacktracking(Row: Integer): Boolean;
var
  Col, I: Integer;
  IsValid: Boolean;
begin
  if Row >= FGridSize then
    Exit(True); // Tüm satırlara kraliçe kondu, bitti!

  for Col := 0 to FGridSize - 1 do
  begin
    IsValid := True;
    // 1. Sütun kontrolü ve 2. Komşuluk (Değmeme) kontrolü
    for I := 0 to Row - 1 do
    begin
      // Aynı sütunda mı?
      if FSolution[I].Y = Col then
        IsValid := False;
      // Komşu hücrelerde mi? (Çapraz veya bitişik)
      if (Abs(FSolution[I].X - Row) <= 1) and (Abs(FSolution[I].Y - Col) <= 1)
      then
        IsValid := False;

      if not IsValid then
        Break;
    end;

    if IsValid then
    begin
      FSolution[Row].X := Row;
      FSolution[Row].Y := Col;
      if PlaceQueensBacktracking(Row + 1) then
        Exit(True);
    end;
  end;
  Result := False;
end;

procedure TOctailyQueensGenerator.GenerateDailyPuzzle;
var
  R, C, I, TargetR, TargetC, Dir: Integer;
  Changed: Boolean;
  Dirs: array [0 .. 3] of TPoint;
begin
  ClearGrid;
  Randomize;

  // Yönleri tanımlayalım (Yukarı, Aşağı, Sol, Sağ)
  Dirs[0].X := -1;
  Dirs[0].Y := 0;
  Dirs[1].X := 1;
  Dirs[1].Y := 0;
  Dirs[2].X := 0;
  Dirs[2].Y := -1;
  Dirs[3].X := 0;
  Dirs[3].Y := 1;

  // 1. Kraliçeleri yerleştir
  SetLength(FSolution, FGridSize);
  if not PlaceQueensBacktracking(0) then
  begin
    // Eğer çözüm bulunamazsa (çok düşük ihtimal) tekrar dene veya varsayılan dön
    GenerateDailyPuzzle;
    Exit;
  end;

  // 2. Bölgeleri Kraliçelerin olduğu yerlerden başlat (Tohumlama)
  // Önce gridi -1 (boş) ile doldur
  for R := 0 to FGridSize - 1 do
    for C := 0 to FGridSize - 1 do
      FRegions[R, C] := -1;

  for I := 0 to FGridSize - 1 do
    FRegions[FSolution[I].X, FSolution[I].Y] := I;

  // 3. Boş hücreleri rastgele büyüterek doldur
  repeat
    Changed := False;
    for R := 0 to FGridSize - 1 do
      for C := 0 to FGridSize - 1 do
      begin
        if FRegions[R, C] = -1 then // Eğer hücre hala boşsa
        begin
          // Sadece bir yöne değil, 4 yöne de sırayla bak
          for Dir := 0 to 3 do
          begin
            TargetR := R + Dirs[Dir].X;
            TargetC := C + Dirs[Dir].Y;

            if (TargetR >= 0) and (TargetR < FGridSize) and (TargetC >= 0) and
              (TargetC < FGridSize) and (FRegions[TargetR, TargetC] <> -1) then
            begin
              FRegions[R, C] := FRegions[TargetR, TargetC];
              Changed := True;
              Break; // Bir komşu bulduk, bu hücre için diğer yönlere bakmaya gerek yok
            end;
          end;
        end;
      end;
  until not Changed;

  FGameDate := Date;
end;

function TOctailyQueensGenerator.GetDailyPuzzleJSON: TJSONObject;
var
  RowsArray, RowData: TJSONArray;
  R, C: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('grid_size', TJSONNumber.Create(FGridSize));

  // Client'a bölgeleri gönderiyoruz (Kraliçeler gizli!)
  RowsArray := TJSONArray.Create;
  for R := 0 to FGridSize - 1 do
  begin
    RowData := TJSONArray.Create;
    for C := 0 to FGridSize - 1 do
      RowData.Add(FRegions[R, C]);
    RowsArray.AddElement(RowData); // Hangi hücre hangi bölgeye ait
  end;

  Result.AddPair('regions', RowsArray);
end;

function TOctailyQueensGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  JSONGuess: TJSONArray;
  GuessPoints: TArray<TPoint>;
  I: Integer;
  TempItem: TJSONValue;
begin
  Result := TJSONObject.Create;
  Result.AddPair('game', FGameName);

  try
    JSONGuess := TJSONObject.ParseJSONValue(AGuess) as TJSONArray;
    if Assigned(JSONGuess) then
    begin
      SetLength(GuessPoints, JSONGuess.Count);
      for I := 0 to JSONGuess.Count - 1 do
      begin
        // İstemciden gelen veri formatı örn: [{"x":0, "y":2}, ...]
        TempItem := JSONGuess.Items[I];
        GuessPoints[I].X := TempItem.GetValue<Integer>('x');
        GuessPoints[I].Y := TempItem.GetValue<Integer>('y');
      end;

      if IsValidPlacement(GuessPoints) then
      begin
        Result.AddPair('success', TJSONBool.Create(True));
        Result.AddPair('status', 'solved');
        Result.AddPair('message', 'Tebrikler, tüm kraliçeler güvende!');
      end
      else
      begin
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('status', 'invalid');
        Result.AddPair('message', 'Kraliçeler birbiriyle çatışıyor!');
      end;
    end;
  except
    on E: Exception do
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', 'Geçersiz veri formatı');
    end;
  end;
end;

end.
