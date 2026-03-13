unit uQueensGenerator;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, uBaseGenerator;

type
  TSetOfByte = set of 0 .. 255;

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
    procedure GrowRegionsOrganically;
  public
    constructor Create(AGameName: string; ASize: Integer = 8); reintroduce;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;
    function GetDebugAnswer: string; override;
  end;

implementation

{ TOctailyQueensGenerator }

constructor TOctailyQueensGenerator.Create(AGameName: string; ASize: Integer);
begin
  inherited Create(AGameName);
  FGridSize := ASize;
end;

function TOctailyQueensGenerator.GetDebugAnswer: string;
var
  P: TPoint;
begin
  Result := '';
  for P in FSolution do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + Format('(%d,%d)', [P.X, P.Y]);
  end;

  if Result = '' then
    Result := 'Çözüm dizisi boş (henüz üretilmemiş).';
end;

procedure TOctailyQueensGenerator.ClearGrid;
begin
  SetLength(FRegions, FGridSize, FGridSize);
  SetLength(FSolution, 0);
end;

function TOctailyQueensGenerator.IsValidPlacement(const APoints: TArray<TPoint>): Boolean;
var
  I, J: Integer;
  P1, P2: TPoint;
begin
  Result := False;

  if Length(APoints) <> FGridSize then Exit;

  for I := 0 to High(APoints) do
  begin
    P1 := APoints[I];

    if (P1.X < 0) or (P1.X >= FGridSize) or (P1.Y < 0) or (P1.Y >= FGridSize) then Exit;

    for J := I + 1 to High(APoints) do
    begin
      P2 := APoints[J];

      if P1.X = P2.X then Exit; // Aynı Satır
      if P1.Y = P2.Y then Exit; // Aynı Sütun
      if FRegions[P1.X, P1.Y] = FRegions[P2.X, P2.Y] then Exit; // Aynı Bölge

      // Çapraz veya bitişik dokunma kontrolü
      if (Abs(P1.X - P2.X) <= 1) and (Abs(P1.Y - P2.Y) <= 1) then Exit;
    end;
  end;

  Result := True;
end;

function TOctailyQueensGenerator.PlaceQueensBacktracking(Row: Integer): Boolean;
var
  I, J, Col, Temp: Integer;
  IsValid: Boolean;
  Cols: TArray<Integer>;
begin
  if Row >= FGridSize then Exit(True);

  // 1. ADIM: Sütunları rastgele karıştır ki her gün aynı bulmaca çıkmasın!
  SetLength(Cols, FGridSize);
  for I := 0 to FGridSize - 1 do Cols[I] := I;

  for I := FGridSize - 1 downto 1 do
  begin
    J := Random(I + 1);
    Temp := Cols[I];
    Cols[I] := Cols[J];
    Cols[J] := Temp;
  end;

  // 2. ADIM: Karıştırılmış sütunları dene
  for I := 0 to FGridSize - 1 do
  begin
    Col := Cols[I];
    IsValid := True;

    for J := 0 to Row - 1 do
    begin
      if FSolution[J].Y = Col then IsValid := False;
      if (Abs(FSolution[J].X - Row) <= 1) and (Abs(FSolution[J].Y - Col) <= 1) then IsValid := False;

      if not IsValid then Break;
    end;

    if IsValid then
    begin
      FSolution[Row].X := Row;
      FSolution[Row].Y := Col;
      if PlaceQueensBacktracking(Row + 1) then Exit(True);
    end;
  end;
  Result := False;
end;

procedure TOctailyQueensGenerator.GrowRegionsOrganically;
var
  R, C, Reg, PickIndex: Integer;
  EmptyCount: Integer;
  Candidates: TArray<TPoint>;
  Target: TPoint;
begin
  EmptyCount := (FGridSize * FGridSize) - FGridSize;

  // Tüm hücreler dolana kadar döngü devam etsin
  while EmptyCount > 0 do
  begin
    // Her bölgeye (renge) adil bir şekilde sırayla "1 kare büyüme" hakkı veriyoruz
    for Reg := 0 to FGridSize - 1 do
    begin
      if EmptyCount = 0 then Break;

      SetLength(Candidates, 0);

      // Bu bölgenin etrafındaki boş hücreleri (adayları) topla
      for R := 0 to FGridSize - 1 do
      begin
        for C := 0 to FGridSize - 1 do
        begin
          if FRegions[R, C] = -1 then // Boş bir hücre ise komşularına bak
          begin
            if ((R > 0) and (FRegions[R-1, C] = Reg)) or
               ((R < FGridSize - 1) and (FRegions[R+1, C] = Reg)) or
               ((C > 0) and (FRegions[R, C-1] = Reg)) or
               ((C < FGridSize - 1) and (FRegions[R, C+1] = Reg)) then
            begin
              SetLength(Candidates, Length(Candidates) + 1);
              Candidates[High(Candidates)].X := R;
              Candidates[High(Candidates)].Y := C;
            end;
          end;
        end;
      end;

      // Eğer bu bölgenin genişleyebileceği aday hücreler varsa RASTGELE birini seç ve fethet!
      if Length(Candidates) > 0 then
      begin
        PickIndex := Random(Length(Candidates));
        Target := Candidates[PickIndex];
        FRegions[Target.X, Target.Y] := Reg;
        Dec(EmptyCount);
      end;
    end;
  end;
end;

procedure TOctailyQueensGenerator.GenerateDailyPuzzle;
var
  R, C, I: Integer;
begin
  ClearGrid;
  Randomize; // Rastgeleliği başlat!

  // 1. Kraliçeleri rastgele yerleştir
  SetLength(FSolution, FGridSize);
  if not PlaceQueensBacktracking(0) then
  begin
    GenerateDailyPuzzle; // Çok düşük bir ihtimal de olsa bulamazsa yeniden başlat
    Exit;
  end;

  // 2. Gridi -1 ile doldur (Boş tahta)
  for R := 0 to FGridSize - 1 do
    for C := 0 to FGridSize - 1 do
      FRegions[R, C] := -1;

  // 3. Kraliçelerin olduğu yerleri "Tohum" olarak ek.
  for I := 0 to FGridSize - 1 do
    FRegions[FSolution[I].X, FSolution[I].Y] := I;

  // 4. Organik / Tetris Büyüme Algoritmasını Çalıştır
  GrowRegionsOrganically;

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

  RowsArray := TJSONArray.Create;
  for R := 0 to FGridSize - 1 do
  begin
    RowData := TJSONArray.Create;
    for C := 0 to FGridSize - 1 do
      RowData.Add(FRegions[R, C]);
    RowsArray.AddElement(RowData);
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
        TempItem := JSONGuess.Items[I];
        GuessPoints[I].X := TempItem.GetValue<Integer>('r'); // 'r' ve 'c' olarak geliyordu sanırım
        GuessPoints[I].Y := TempItem.GetValue<Integer>('c');
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
