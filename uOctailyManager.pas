unit uOctailyManager;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  uBaseGenerator, uWordleGenerator, uQueensGenerator, uNerdleGenerator,
  uZipGenerator, uHexleGenerator, uWorldleGenerator, uSudokuGenerator;

type
  TOctailyManager = class
  private
  class var
    FInstance: TOctailyManager;
    FGenerators: TObjectDictionary<string, TOctailyBaseGenerator>;
    FLastRefreshDate: TDateTime;

    procedure InitializeGenerators;
    procedure CheckAndRefresh;
  public
    constructor Create;
    destructor Destroy; override;
    class function Instance: TOctailyManager;

    function GetPuzzle(const AGameName: string): TJSONObject;
    function PostGuess(const AGameName: string; const AGuess: string)
      : TJSONObject;
    procedure ForceRefresh; // Manuel yenileme gerekirse
    function GetAnswer(const AGameName: string): string;
  end;

implementation

{ TOctailyManager }

uses Unit1;

constructor TOctailyManager.Create;
begin
  FGenerators := TObjectDictionary<string, TOctailyBaseGenerator>.Create
    ([doOwnsValues]);
  InitializeGenerators;
  FLastRefreshDate := 0;
  CheckAndRefresh;
end;

destructor TOctailyManager.Destroy;
begin
  FGenerators.Free;
  inherited;
end;

class function TOctailyManager.Instance: TOctailyManager;
begin
  if not Assigned(FInstance) then
    FInstance := TOctailyManager.Create;
  Result := FInstance;
end;

function TOctailyManager.GetAnswer(const AGameName: string): string;
var
  Gen: TOctailyBaseGenerator;
begin
  CheckAndRefresh;
  // Cevabı vermeden önce güncel bulmaca üretilmiş mi kontrol et

  if FGenerators.TryGetValue(AGameName.ToLower, Gen) then
  begin
    // Jeneratörden cevabı string olarak talep et
    Result := Gen.GetDebugAnswer;
  end
  else
    Result := 'Hata: Oyun bulunamadı!';
end;

procedure TOctailyManager.InitializeGenerators;
begin
  FGenerators.Add('wordle_tr', TOctailyWordleGenerator.Create('wordle_tr',
    ExtractFilePath(ParamStr(0)) + 'data/wordle_tr.txt'));
  FGenerators.Add('wordle_en', TOctailyWordleGenerator.Create('wordle_en',
    ExtractFilePath(ParamStr(0)) + 'data/wordle_en.txt'));
  FGenerators.Add('queens', TOctailyQueensGenerator.Create('queens'));
  FGenerators.Add('nerdle', TOctailyNerdleGenerator.Create('nerdle'));
  FGenerators.Add('zip', TOctailyZipGenerator.Create('zip'));
  FGenerators.Add('hexle', TOctailyHexleGenerator.Create('hexle'));
  FGenerators.Add('worldle', TOctailyWorldleGenerator.Create('worldle'));
  FGenerators.Add('sudoku', TOctailySudokuGenerator.Create('sudoku'));
end;

procedure TOctailyManager.CheckAndRefresh;
var
  Generator: TOctailyBaseGenerator;
begin
  if Trunc(FLastRefreshDate) < Trunc(Now) then
  begin
    for Generator in FGenerators.Values do
      Generator.GenerateDailyPuzzle;

    FLastRefreshDate := Now;

    // Form1'deki Memo'ya veya Butona ASLA dokunmuyoruz. Direkt dosyaya kusuyoruz:
    Form1.LogYaz('=============================================');
    Form1.LogYaz('YENİ GÜN BAŞLADI: Tüm Bulmacalar Yenilendi.');
    Form1.LogYaz('Wordle TR Cevabı: ' + GetAnswer('wordle_tr'));
    Form1.LogYaz('Wordle EN Cevabı: ' + GetAnswer('wordle_en'));
    Form1.LogYaz('Sudoku Cevabı: ' + GetAnswer('sudoku'));
    Form1.LogYaz('Queens Cevabı: ' + GetAnswer('queens'));
    Form1.LogYaz('Nerdle Cevabı: ' + GetAnswer('nerdle'));
    Form1.LogYaz('Zip Cevabı: ' + GetAnswer('zip'));
    Form1.LogYaz('Hexle Cevabı: ' + GetAnswer('hexle'));
    Form1.LogYaz('Worldle Cevabı: ' + GetAnswer('worldle'));
    Form1.LogYaz('=============================================');
  end;
end;

function TOctailyManager.GetPuzzle(const AGameName: string): TJSONObject;
var
  Gen: TOctailyBaseGenerator;
begin
  CheckAndRefresh; // Her istekte gün kontrolü yap

  if FGenerators.TryGetValue(AGameName.ToLower, Gen) then
    Result := Gen.GetDailyPuzzleJSON
  else
  begin
    Result := TJSONObject.Create;
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Oyun bulunamadı: ' + AGameName);
  end;
end;

function TOctailyManager.PostGuess(const AGameName: string;
  const AGuess: string): TJSONObject;
var
  Gen: TOctailyBaseGenerator;
begin
  CheckAndRefresh;

  if FGenerators.TryGetValue(AGameName.ToLower, Gen) then
    Result := Gen.CheckGuess(AGuess)
  else
  begin
    Result := TJSONObject.Create;
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Oyun bulunamadı: ' + AGameName);
  end;
end;

procedure TOctailyManager.ForceRefresh;
begin
  FLastRefreshDate := 0; // Tarihi sıfırla ki CheckAndRefresh çalışsın
  CheckAndRefresh;
end;

initialization

finalization

if Assigned(TOctailyManager.FInstance) then
  TOctailyManager.FInstance.Free;

end.
