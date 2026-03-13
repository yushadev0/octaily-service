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
    FSolutionPath: TList<TPoint>; // Sunucunun ürettiği gizli çözüm
    FGridNumbers: array of array of Integer; // Durak rakamları (1, 2, 3...)

    function FindRandomPath(CurrX, CurrY: Integer;
      Visited: TArray<TArray<Boolean>>; Count: Integer): Boolean;
    procedure ClearGrid;
    function IsAdjacent(P1, P2: TPoint): Boolean;

  public
    constructor Create(AGameName: string; ASize: Integer = 5); reintroduce;
    destructor Destroy; override;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;
    function GetDebugAnswer: string; override;
  end;

implementation

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
begin
  SetLength(FGridNumbers, FGridSize, FGridSize);
  FSolutionPath.Clear;
end;

function TOctailyZipGenerator.IsAdjacent(P1, P2: TPoint): Boolean;
begin
  // Sadece yatay veya dikey komşuluk (Manhattan mesafesi = 1)
  Result := Abs(P1.X - P2.X) + Abs(P1.Y - P2.Y) = 1;
end;

function TOctailyZipGenerator.FindRandomPath(CurrX, CurrY: Integer;
  Visited: TArray<TArray<Boolean>>; Count: Integer): Boolean;
var
  Dirs: array [0 .. 3] of TPoint;
  I, NextX, NextY, RandIdx: Integer;
  Temp: TPoint;
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

  for I := 0 to 3 do
  begin
    RandIdx := Random(4);
    Temp := Dirs[I];
    Dirs[I] := Dirs[RandIdx];
    Dirs[RandIdx] := Temp;
  end;

  for I := 0 to 3 do
  begin
    NextX := CurrX + Dirs[I].X;
    NextY := CurrY + Dirs[I].Y;
    if (NextX >= 0) and (NextX < FGridSize) and (NextY >= 0) and
      (NextY < FGridSize) and (not Visited[NextX, NextY]) then
    begin
      Visited[NextX, NextY] := True;
      Temp.X := NextX;
      Temp.Y := NextY;
      FSolutionPath.Add(Temp);
      if FindRandomPath(NextX, NextY, Visited, Count + 1) then
        Exit(True);
      FSolutionPath.Delete(FSolutionPath.Count - 1);
      Visited[NextX, NextY] := False;
    end;
  end;
  Result := False;
end;

procedure TOctailyZipGenerator.GenerateDailyPuzzle;
var
  Visited: TArray<TArray<Boolean>>;
  R, C, WaypointValue, Step, I: Integer;
  StartPos: TPoint;
begin
  ClearGrid;
  Randomize;
  SetLength(Visited, FGridSize, FGridSize);
  for R := 0 to FGridSize - 1 do
    for C := 0 to FGridSize - 1 do
    begin
      Visited[R, C] := False;
      FGridNumbers[R, C] := 0;
    end;

  StartPos.X := Random(FGridSize);
  StartPos.Y := Random(FGridSize);
  Visited[StartPos.X, StartPos.Y] := True;
  FSolutionPath.Add(StartPos);

  if FindRandomPath(StartPos.X, StartPos.Y, Visited, 1) then
  begin
    // 1. Durak (Başlangıç)
    FGridNumbers[FSolutionPath[0].X, FSolutionPath[0].Y] := 1;

    // Ara Duraklar (Waypoints)
    WaypointValue := 2;
    Step := (FGridSize * FGridSize) div 4; // Her %25'lik dilime bir durak
    for I := 1 to 2 do
    begin
      R := (I * Step) + Random(2);
      FGridNumbers[FSolutionPath[R].X, FSolutionPath[R].Y] := WaypointValue;
      Inc(WaypointValue);
    end;

    // Son Durak (Bitiş)
    FGridNumbers[FSolutionPath[FSolutionPath.Count - 1].X,
      FSolutionPath[FSolutionPath.Count - 1].Y] := WaypointValue;
  end;
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
  VisitedCount: Integer;
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

    // 1. KURAL: Tüm hücreler gezilmeli mi?
    if JSONGuess.Count <> (FGridSize * FGridSize) then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('error', 'Tüm hücreleri ziyaret etmelisiniz!');
      Exit;
    end;

    SetLength(GridVisited, FGridSize, FGridSize);
    ExpectedWaypoint := 1;
    VisitedCount := 0;

    for I := 0 to JSONGuess.Count - 1 do
    begin
      P.X := JSONGuess.Items[I].GetValue<Integer>('x');
      P.Y := JSONGuess.Items[I].GetValue<Integer>('y');

      // Sınır kontrolü ve Çift ziyaret kontrolü
      if (P.X < 0) or (P.X >= FGridSize) or (P.Y < 0) or (P.Y >= FGridSize) or
        GridVisited[P.X, P.Y] then
      begin
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('error', 'Geçersiz hamle veya hücre tekrarı!');
        Exit;
      end;

      // 2. KURAL: Bitişiklik (Adjacency) - İlk hücre hariç
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

      // 3. KURAL: Durak Sıralaması (Waypoints)
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
      Inc(VisitedCount);
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Harika! Hamilton yolunu tamamladın.');

  except
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Sunucu hatası');
  end;
end;

end.
