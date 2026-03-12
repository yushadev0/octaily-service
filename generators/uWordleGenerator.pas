unit uWordleGenerator;

interface

uses
  System.SysUtils, System.JSON, System.Classes, System.Math, uBaseGenerator;

type
  TOctailyWordleGenerator = class(TOctailyBaseGenerator)
  private
    FWordList: TStringList;
    FDailyWord: string;
    FDataFilePath: string;
    procedure LoadWords;
  public
    constructor Create(AGameName, ADataFilePath: string); reintroduce;
    destructor Destroy; override;

    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;
    property DailyWord: string read FDailyWord;
  end;

implementation

{ TOctailyWordleGenerator }

constructor TOctailyWordleGenerator.Create(AGameName, ADataFilePath: string);
begin
  inherited Create(AGameName);
  FDataFilePath := ADataFilePath;
  FWordList := TStringList.Create;
  LoadWords;
end;

destructor TOctailyWordleGenerator.Destroy;
begin
  FWordList.Free;
  inherited;
end;

procedure TOctailyWordleGenerator.LoadWords;
begin
  if FileExists(FDataFilePath) then
    // Eskisi: FWordList.LoadFromFile(FDataFilePath);
    // YENİSİ: TEncoding.UTF8 parametresini ekliyoruz!
    FWordList.LoadFromFile(FDataFilePath, TEncoding.UTF8)
  else
    raise Exception.CreateFmt('%s için kelime dosyası bulunamadı: %s', [FGameName, FDataFilePath]);
end;
procedure TOctailyWordleGenerator.GenerateDailyPuzzle;
begin
  if FWordList.Count > 0 then
  begin
    Randomize;
    FDailyWord := UpperCase(FWordList[Random(FWordList.Count)]);
    FGameDate := Date;
  end;
end;

function TOctailyWordleGenerator.GetDailyPuzzleJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('date', DateToStr(FGameDate));

  Result.AddPair('word_length', TJSONNumber.Create(5));
  Result.AddPair('message', 'Bugünün kelimesi hazir, tahminlerini bekliyorum!');
end;

function TOctailyWordleGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  JSONArray: TJSONArray;
  LetterObj: TJSONObject;
  I, J: Integer;
  GuessUpper, TargetUpper: string;
  TargetMatched, GuessMatched: array[1..5] of Boolean;
  Statuses: array[1..5] of string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('guess', UpperCase(AGuess));

  JSONArray := TJSONArray.Create;
  GuessUpper := UpperCase(AGuess);
  TargetUpper := FDailyWord;

  // Güvenlik: Kelime 5 harfli mi ve günün kelimesi hazır mı?
  if (Length(GuessUpper) <> 5) or (Length(TargetUpper) <> 5) then
  begin
     Result.AddPair('error', 'Geçersiz kelime uzunluğu veya günün kelimesi üretilmemiş.');
     Result.AddPair('result', JSONArray);
     Exit;
  end;

  // Dizileri sıfırla
  for I := 1 to 5 do
  begin
    TargetMatched[I] := False;
    GuessMatched[I] := False;
    Statuses[I] := 'absent'; // Başlangıçta hepsi Gri (absent)
  end;

  // 1. AŞAMA: Doğru yerdeki harfler (Yeşil / correct)
  for I := 1 to 5 do
  begin
    if GuessUpper[I] = TargetUpper[I] then
    begin
      Statuses[I] := 'correct';
      TargetMatched[I] := True;
      GuessMatched[I] := True;
    end;
  end;

  // 2. AŞAMA: Yanlış yerdeki harfler (Sarı / present)
  for I := 1 to 5 do
  begin
    if not GuessMatched[I] then
    begin
      for J := 1 to 5 do
      begin
        if (not TargetMatched[J]) and (GuessUpper[I] = TargetUpper[J]) then
        begin
          Statuses[I] := 'present';
          TargetMatched[J] := True;
          Break;
        end;
      end;
    end;
  end;

  for I := 1 to 5 do
  begin
    LetterObj := TJSONObject.Create;
    LetterObj.AddPair('letter', GuessUpper[I]);
    LetterObj.AddPair('status', Statuses[I]);
    JSONArray.AddElement(LetterObj);
  end;

  Result.AddPair('result', JSONArray);
end;

end.
