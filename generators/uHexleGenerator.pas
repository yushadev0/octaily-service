unit uHexleGenerator;

interface

uses
  System.SysUtils, System.JSON, uBaseGenerator;

type
  TOctailyHexleGenerator = class(TOctailyBaseGenerator)
  private
    const HEX_CHARS = '0123456789ABCDEF';
  private
    FDailyHex: string; // Örn: "3A8C55"
    function GetHexValue(AChar: Char): Integer;
  public
    constructor Create(AGameName: string); reintroduce;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;

    property DailyHex: string read FDailyHex;
  end;

implementation

{ TOctailyHexleGenerator }

constructor TOctailyHexleGenerator.Create(AGameName: string);
begin
  inherited Create(AGameName);
end;

function TOctailyHexleGenerator.GetHexValue(AChar: Char): Integer;
begin
  // Karakterin HEX dizisindeki yerini döndürür (0-15 arası)
  Result := Pos(UpperCase(AChar), HEX_CHARS) - 1;
end;

procedure TOctailyHexleGenerator.GenerateDailyPuzzle;
var
  I: Integer;
begin
  Randomize;
  FDailyHex := '';
  // 6 haneli rastgele bir HEX kodu oluştur
  for I := 1 to 6 do
    FDailyHex := FDailyHex + HEX_CHARS[Random(16) + 1];

  FGameDate := Date;
end;

function TOctailyHexleGenerator.GetDailyPuzzleJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
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

    // Aradaki farkı hesapla (Hedef - Tahmin)
    Diff := TargetVal - GuessVal;

    CharObj := TJSONObject.Create;
    CharObj.AddPair('char', GuessChar);

    if Diff = 0 then
      CharObj.AddPair('status', 'correct')
    else if Diff > 0 then
    begin
      // Hedef daha yukarıda
      if Diff > 3 then
        CharObj.AddPair('status', 'very_higher') // Mesafe uzak (3'ten büyük)
      else
        CharObj.AddPair('status', 'higher');      // Mesafe yakın
    end
    else
    begin
      // Hedef daha aşağıda
      if Abs(Diff) > 3 then
        CharObj.AddPair('status', 'very_lower')  // Mesafe uzak
      else
        CharObj.AddPair('status', 'lower');       // Mesafe yakın
    end;

    JSONArray.AddElement(CharObj);
  end;

  Result.AddPair('result', JSONArray);
end;
end.
