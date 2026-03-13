unit uHexleGenerator;

interface

uses
  System.SysUtils, System.JSON, uBaseGenerator;

type
  TOctailyHexleGenerator = class(TOctailyBaseGenerator)
  private const
    HEX_CHARS = '0123456789ABCDEF';
  private
    FDailyHex: string; // Örn: "3A8C55"
    FPuzzleID: string; // Senkronizasyon için ID eklendi
    function GetHexValue(AChar: Char): Integer;

  public
    constructor Create(AGameName: string); reintroduce;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;

    property DailyHex: string read FDailyHex;
    function GetDebugAnswer: string; override;
  end;

implementation

{ TOctailyHexleGenerator }

constructor TOctailyHexleGenerator.Create(AGameName: string);
begin
  inherited Create(AGameName);
end;

function TOctailyHexleGenerator.GetHexValue(AChar: Char): Integer;
begin
  Result := Pos(UpperCase(AChar), HEX_CHARS) - 1;
end;

function TOctailyHexleGenerator.GetDebugAnswer: string;
begin
  Result := FDailyHex;
end;

procedure TOctailyHexleGenerator.GenerateDailyPuzzle;
var
  I: Integer;
begin
  Randomize;
  FDailyHex := '';

  for I := 1 to 6 do
    FDailyHex := FDailyHex + HEX_CHARS[Random(16) + 1];

  FPuzzleID := FormatDateTime('yyyymmdd_hhnnss', Now);
  FGameDate := Date;
end;

function TOctailyHexleGenerator.GetDailyPuzzleJSON: TJSONObject;
var
  R, G, B: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('id', FPuzzleID);

  // HİLE KORUMASI: Cevap olan HEX kodunu parçalayıp RGB'ye çeviriyoruz
  // Böylece JSON içinde "3A8C55" yazmayacak, "rgb(58, 140, 85)" yazacak.
  R := StrToInt('$' + Copy(FDailyHex, 1, 2));
  G := StrToInt('$' + Copy(FDailyHex, 3, 2));
  B := StrToInt('$' + Copy(FDailyHex, 5, 2));

  Result.AddPair('target_color', Format('rgb(%d, %d, %d)', [R, G, B]));
  Result.AddPair('message', 'Renk kodu hazir, 6 haneli HEX tahminini bekliyorum!');
end;

function TOctailyHexleGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  JSONArray: TJSONArray;
  CharObj: TJSONObject;
  I: Integer;
  GuessChar, TargetChar: Char;
  GuessVal, TargetVal, Diff: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('game', FGameName);

  AGuess := UpperCase(StringReplace(AGuess, '#', '', [rfReplaceAll]));

  if Length(AGuess) <> 6 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'HEX kodu tam 6 karakter olmalıdır!');
    Exit;
  end;

  Result.AddPair('success', TJSONBool.Create(True));
  JSONArray := TJSONArray.Create;

  for I := 1 to 6 do
  begin
    GuessChar := AGuess[I];
    TargetChar := FDailyHex[I];
    GuessVal := GetHexValue(GuessChar);
    TargetVal := GetHexValue(TargetChar);

    Diff := TargetVal - GuessVal;

    CharObj := TJSONObject.Create;
    CharObj.AddPair('char', GuessChar);

    if Diff = 0 then
      CharObj.AddPair('status', 'correct')
    else if Diff > 0 then
    begin
      if Diff > 3 then
        CharObj.AddPair('status', 'very_higher')
      else
        CharObj.AddPair('status', 'higher');
    end
    else
    begin
      if Abs(Diff) > 3 then
        CharObj.AddPair('status', 'very_lower')
      else
        CharObj.AddPair('status', 'lower');
    end;

    JSONArray.AddElement(CharObj);
  end;

  Result.AddPair('result', JSONArray);
end;

end.
