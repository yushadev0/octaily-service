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
    FWordList.LoadFromFile(FDataFilePath)
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
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('guess', UpperCase(AGuess));

  JSONArray := TJSONArray.Create;

  // Harf kontrol algoritması (Yeşil, Sarı, Gri) buraya eklenecek
  Result.AddPair('result', JSONArray);
end;

end.
