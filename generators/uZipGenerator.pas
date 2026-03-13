unit uZipGenerator;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, System.Math,
  uBaseGenerator;

type
  TPoint = record
    X, Y: Integer;
  end;

  TOctailyZipGenerator = class(TOctailyBaseGenerator)
  private
    FGridSize: Integer;
    FPuzzleID: string;
    FSolutionPath: TList<TPoint>;
    FGridNumbers: TArray<TArray<Integer>>;

    function GetUnvisitedNeighborsCount(X, Y: Integer;
      const Visited: TArray < TArray < Boolean >> ): Integer;
    function FindRandomPath(CurrX, CurrY: Integer;
      var Visited: TArray<TArray<Boolean>>; Count: Integer): Boolean;
    procedure ClearGrid;
    function IsAdjacent(P1, P2: TPoint): Boolean;

  public
    // Varsayılan boyut artık 8 (8x8 = 64 Hücre)
    constructor Create(AGameName: string; ASize: Integer = 8); reintroduce;
    destructor Destroy; override;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;
    function GetDebugAnswer: string; override;
  end;

implementation

type
  TNeighbor = record
    Pos: TPoint;
    Degree: Integer;
  end;

  { TOctailyZipGenerator }

constructor TOctailyZipGenerator.Create(AGameName: string; ASize: Integer);
begin
  inherited Create(AGameName);
  FGridSize := ASize;
  FSolutionPath := TList<TPoint>.Create;
end;

destructor TOctailyZipGenerator.Destroy;
begin
  FSolutionPath.Free;
  inherited;
end;

function TOctailyZipGenerator.GetDebugAnswer: string;
var
  P: TPoint;
begin
  Result := '';
  if Assigned(FSolutionPath) and (FSolutionPath.Count > 0) then
  begin
    for P in FSolutionPath do
    begin
      if Result <> '' then
        Result := Result + ' -> ';
      Result := Result + Format('(%d,%d)', [P.X, P.Y]);
    end;
  end
  else
    Result := 'Çözüm yolu henüz oluşturulmamış veya boş.';
end;

procedure TOctailyZipGenerator.ClearGrid;
var
  R, C: Integer;
begin
  SetLength(FGridNumbers, FGridSize, FGridSize);
  for R := 0 to FGridSize - 1 do
    for C := 0 to FGridSize - 1 do
      FGridNumbers[R, C] := 0;

  FSolutionPath.Clear;
end;

function TOctailyZipGenerator.IsAdjacent(P1, P2: TPoint): Boolean;
begin
  Result := (Abs(P1.X - P2.X) + Abs(P1.Y - P2.Y)) = 1;
end;

// Warnsdorff Sezgisel Kuralı: Bir hücrenin kaç tane gidilmemiş "boş" komşusu var?
function TOctailyZipGenerator.GetUnvisitedNeighborsCount(X, Y: Integer;
  const Visited: TArray < TArray < Boolean >> ): Integer;
var
  I, NX, NY, Cnt: Integer;
  Dirs: array [0 .. 3] of TPoint;
begin
  Cnt := 0;
  Dirs[0].X := 0;
  Dirs[0].Y := -1;
  Dirs[1].X := 0;
  Dirs[1].Y := 1;
  Dirs[2].X := -1;
  Dirs[2].Y := 0;
  Dirs[3].X := 1;
  Dirs[3].Y := 0;

  for I := 0 to 3 do
  begin
    NX := X + Dirs[I].X;
    NY := Y + Dirs[I].Y;
    if (NX >= 0) and (NX < FGridSize) and (NY >= 0) and (NY < FGridSize) then
      if not Visited[NX, NY] then
        Inc(Cnt);
  end;
  Result := Cnt;
end;

// Warnsdorff destekli optimize edilmiş Derinlik Öncelikli Arama (DFS)
function TOctailyZipGenerator.FindRandomPath(CurrX, CurrY: Integer;
  var Visited: TArray<TArray<Boolean>>; Count: Integer): Boolean;
var
  Dirs: array [0 .. 3] of TPoint;
  Neighbors: array [0 .. 3] of TNeighbor;
  I, J, ValidCount, NextX, NextY, RandIdx: Integer;
  TempPoint: TPoint;
  TempNeighbor: TNeighbor;
begin
  if Count = (FGridSize * FGridSize) then
    Exit(True);

  Dirs[0].X := 0;
  Dirs[0].Y := -1;
  Dirs[1].X := 0;
  Dirs[1].Y := 1;
  Dirs[2].X := -1;
  Dirs[2].Y := 0;
  Dirs[3].X := 1;
  Dirs[3].Y := 0;

  // Eşitlik durumlarında rastgeleliği korumak için yönleri başta karıştırıyoruz
  for I := 0 to 3 do
  begin
    RandIdx := Random(4);
    TempPoint := Dirs[I];
    Dirs[I] := Dirs[RandIdx];
    Dirs[RandIdx] := TempPoint;
  end;

  ValidCount := 0;
  for I := 0 to 3 do
  begin
    NextX := CurrX + Dirs[I].X;
    NextY := CurrY + Dirs[I].Y;
    if (NextX >= 0) and (NextX < FGridSize) and (NextY >= 0) and
      (NextY < FGridSize) then
    begin
      if not Visited[NextX, NextY] then
      begin
        Neighbors[ValidCount].Pos.X := NextX;
        Neighbors[ValidCount].Pos.Y := NextY;
        // Bu komşuya gidersek onun kaç boş komşusu kalacak?
        Neighbors[ValidCount].Degree := GetUnvisitedNeighborsCount(NextX,
          NextY, Visited);
        Inc(ValidCount);
      end;
    end;
  end;

  // Warnsdorff: Komşuları çıkış sayısına göre (Degree) KÜÇÜKTEN BÜYÜĞE sırala!
  // Çıkmaz sokağa girmek üzere olan (Degree'si en az olan) hücreyi ilk ziyaret et ki tahta tıkanmasın.
  for I := 0 to ValidCount - 2 do
    for J := I + 1 to ValidCount - 1 do
      if Neighbors[J].Degree < Neighbors[I].Degree then
      begin
        TempNeighbor := Neighbors[I];
        Neighbors[I] := Neighbors[J];
        Neighbors[J] := TempNeighbor;
      end;

  // Sıralanmış en ideal yolları dene
  for I := 0 to ValidCount - 1 do
  begin
    NextX := Neighbors[I].Pos.X;
    NextY := Neighbors[I].Pos.Y;

    Visited[NextX, NextY] := True;
    FSolutionPath.Add(Neighbors[I].Pos);

    if FindRandomPath(NextX, NextY, Visited, Count + 1) then
      Exit(True);

    FSolutionPath.Delete(FSolutionPath.Count - 1); // Backtrack (Geri sar)
    Visited[NextX, NextY] := False;
  end;

  Result := False;
end;

procedure TOctailyZipGenerator.GenerateDailyPuzzle;
var
  Visited: TArray<TArray<Boolean>>;
  R, C, WaypointValue, Step, I, TargetIdx, TotalWaypoints,
    IntermediateCount: Integer;
  StartPos: TPoint;
  Success: Boolean;
begin
  ClearGrid;
  Randomize;

  Success := False;

  while not Success do
  begin
    SetLength(Visited, FGridSize, FGridSize);
    for R := 0 to FGridSize - 1 do
      for C := 0 to FGridSize - 1 do
        Visited[R, C] := False;

    FSolutionPath.Clear;

    StartPos.X := Random(FGridSize);
    StartPos.Y := Random(FGridSize);

    if (FGridSize mod 2 <> 0) and ((StartPos.X + StartPos.Y) mod 2 <> 0) then
      Continue;

    Visited[StartPos.X, StartPos.Y] := True;
    FSolutionPath.Add(StartPos);

    Success := FindRandomPath(StartPos.X, StartPos.Y, Visited, 1);
  end;

  // 1. Durak (Başlangıç)
  FGridNumbers[FSolutionPath[0].X, FSolutionPath[0].Y] := 1;

  // TERLETEN ZORLUK: Rastgele 10 ile 15 arası toplam durak sayısı belirle
  TotalWaypoints := 10 + Random(6); // 10, 11, 12, 13, 14, 15
  IntermediateCount := TotalWaypoints - 2;

  WaypointValue := 2;
  Step := (FGridSize * FGridSize) div (IntermediateCount + 1);

  for I := 1 to IntermediateCount do
  begin
    // Araya biraz rastgelelik kat (Duraklar dümdüz eşit aralıklı olmasın)
    TargetIdx := (I * Step) + Random(Max(1, Step div 2));
    if TargetIdx >= FSolutionPath.Count - 1 then
      Break;

    FGridNumbers[FSolutionPath[TargetIdx].X, FSolutionPath[TargetIdx].Y] :=
      WaypointValue;
    Inc(WaypointValue);
  end;

  // Son Durak (Bitiş)
  FGridNumbers[FSolutionPath[FSolutionPath.Count - 1].X,
    FSolutionPath[FSolutionPath.Count - 1].Y] := WaypointValue;

  FPuzzleID := FormatDateTime('yyyymmdd_hhnnss', Now);
  FGameDate := Date;
end;

function TOctailyZipGenerator.GetDailyPuzzleJSON: TJSONObject;
var
  GridArr, RowArr: TJSONArray;
  R, C: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('id', FPuzzleID);
  Result.AddPair('grid_size', TJSONNumber.Create(FGridSize));

  GridArr := TJSONArray.Create;
  for R := 0 to FGridSize - 1 do
  begin
    RowArr := TJSONArray.Create;
    for C := 0 to FGridSize - 1 do
      RowArr.Add(FGridNumbers[R, C]);
    GridArr.AddElement(RowArr);
  end;
  Result.AddPair('grid', GridArr);
end;

function TOctailyZipGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  JSONGuess: TJSONArray;
  P, PrevP: TPoint;
  I, ExpectedWaypoint: Integer;
  GridVisited: array of array of Boolean;
begin
  Result := TJSONObject.Create;
  Result.AddPair('game', FGameName);

  try
    JSONGuess := TJSONObject.ParseJSONValue(AGuess) as TJSONArray;
    if not Assigned(JSONGuess) then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', 'Geçersiz veri formatı');
      Exit;
    end;

    if JSONGuess.Count <> (FGridSize * FGridSize) then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', 'Tüm hücreleri ziyaret etmelisiniz!');
      Exit;
    end;

    P.X := JSONGuess.Items[0].GetValue<Integer>('x');
    P.Y := JSONGuess.Items[0].GetValue<Integer>('y');
    if FGridNumbers[P.X, P.Y] <> 1 then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', 'Yola 1 numaradan başlamalısınız!');
      Exit;
    end;

    SetLength(GridVisited, FGridSize, FGridSize);
    ExpectedWaypoint := 1;

    for I := 0 to JSONGuess.Count - 1 do
    begin
      P.X := JSONGuess.Items[I].GetValue<Integer>('x');
      P.Y := JSONGuess.Items[I].GetValue<Integer>('y');

      if (P.X < 0) or (P.X >= FGridSize) or (P.Y < 0) or (P.Y >= FGridSize) or
        GridVisited[P.X, P.Y] then
      begin
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('error', 'Geçersiz hamle veya hücre tekrarı!');
        Exit;
      end;

      if I > 0 then
      begin
        PrevP.X := JSONGuess.Items[I - 1].GetValue<Integer>('x');
        PrevP.Y := JSONGuess.Items[I - 1].GetValue<Integer>('y');
        if not IsAdjacent(P, PrevP) then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('error', 'Bağlantı kopukluğu tespit edildi!');
          Exit;
        end;
      end;

      if FGridNumbers[P.X, P.Y] > 0 then
      begin
        if FGridNumbers[P.X, P.Y] <> ExpectedWaypoint then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('error', 'Duraklara yanlış sırayla uğradınız!');
          Exit;
        end;
        Inc(ExpectedWaypoint);
      end;

      GridVisited[P.X, P.Y] := True;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Harika! Hamilton yolunu tamamladın.');

  except
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Sunucu hatası');
  end;
end;

end.
