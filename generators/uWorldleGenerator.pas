unit uWorldleGenerator;

interface

uses
  System.SysUtils, System.JSON, System.Math, System.Generics.Collections,
  uBaseGenerator, System.IOUtils, System.Character;

type
  TCountry = record
    Name: string;      // Normalize edilmiş isim (Örn: TURKIYE)
    OriginalName: string; // Orijinal isim (Gerektiğinde göstermek için)
    Lat, Lon: Double;
    ISO: string;
  end;

  TOctailyWorldleGenerator = class(TOctailyBaseGenerator)
  private
    FCountries: TList<TCountry>;
    FTargetCountry: TCountry;
    procedure LoadCountryData;
    function CalculateDistance(Lat1, Lon1, Lat2, Lon2: Double): Double;
    function CalculateBearing(Lat1, Lon1, Lat2, Lon2: Double): Double;
    function GetDirection(Bearing: Double): string;
    // Karakterleri (İ, Ü, Ç vb.) İngilizce standartlarına çeken yardımcı fonksiyon
    function NormalizeString(const AStr: string): string;
  public
    constructor Create(AGameName: string); reintroduce;
    destructor Destroy; override;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;

    property TargetCountry: TCountry read FTargetCountry;
  end;

implementation

{ TOctailyWorldleGenerator }

constructor TOctailyWorldleGenerator.Create(AGameName: string);
begin
  inherited Create(AGameName);
  FCountries := TList<TCountry>.Create;
  LoadCountryData;
end;

destructor TOctailyWorldleGenerator.Destroy;
begin
  FCountries.Free;
  inherited;
end;

function TOctailyWorldleGenerator.NormalizeString(const AStr: string): string;
begin
  // Tüm karakterleri büyük harfe çevir ve Türkçe/Aksanlı karakterleri temizle
  Result := AStr.Trim.ToUpper;
  Result := Result.Replace('İ', 'I').Replace('Ü', 'U').Replace('Ö', 'O')
                  .Replace('Ğ', 'G').Replace('Ş', 'S').Replace('Ç', 'C')
                  .Replace('Â', 'A').Replace('Ê', 'E').Replace('Î', 'I')
                  .Replace('Ô', 'O').Replace('Û', 'U');
end;

procedure TOctailyWorldleGenerator.LoadCountryData;
var
  LFilePath: string;
  LJSONContent: string;
  LJSONArray, LLatLng: TJSONArray;
  LJSONItem: TJSONObject;
  I: Integer;
  C: TCountry;
  LFS: TFormatSettings;
begin
  LFS := TFormatSettings.Invariant; // Ondalık nokta (.) için zorunlu

  // JSON dosyasının veri (data) klasöründe olduğunu varsayıyoruz
  LFilePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data/countries.json');

  if not TFile.Exists(LFilePath) then
    raise Exception.Create('Hata: data/countries.json bulunamadı!');

  LJSONContent := TFile.ReadAllText(LFilePath, TEncoding.UTF8);
  LJSONArray := TJSONObject.ParseJSONValue(LJSONContent) as TJSONArray;

  if Assigned(LJSONArray) then
  try
    FCountries.Clear;
    for I := 0 to LJSONArray.Count - 1 do
    begin
      LJSONItem := LJSONArray.Items[I] as TJSONObject;

      // İsmi hem orijinal hem de arama için normalize edilmiş halde tutuyoruz
      C.OriginalName := LJSONItem.GetValue<TJSONObject>('name').GetValue<string>('common');
      C.Name := NormalizeString(C.OriginalName);

      LLatLng := LJSONItem.GetValue<TJSONArray>('latlng');
      if (LLatLng <> nil) and (LLatLng.Count >= 2) then
      begin
        C.Lat := StrToFloat(LLatLng.Items[0].Value, LFS);
        C.Lon := StrToFloat(LLatLng.Items[1].Value, LFS);

        C.ISO := LJSONItem.GetValue<string>('cca2');
        FCountries.Add(C);
      end;
    end;
  finally
    LJSONArray.Free;
  end;
end;

function TOctailyWorldleGenerator.CalculateDistance(Lat1, Lon1, Lat2, Lon2: Double): Double;
var
  dLat, dLon, a, c_val: Double;
const
  R = 6371; // Dünya yarıçapı
begin
  dLat := DegToRad(Lat2 - Lat1);
  dLon := DegToRad(Lon2 - Lon1);
  a := Sin(dLat / 2) * Sin(dLat / 2) + Cos(DegToRad(Lat1)) * Cos(DegToRad(Lat2))
    * Sin(dLon / 2) * Sin(dLon / 2);
  c_val := 2 * ArcTan2(Sqrt(a), Sqrt(1 - a));
  Result := R * c_val;
end;

function TOctailyWorldleGenerator.CalculateBearing(Lat1, Lon1, Lat2, Lon2: Double): Double;
var
  y, x: Double;
begin
  Lat1 := DegToRad(Lat1); Lat2 := DegToRad(Lat2);
  Lon1 := DegToRad(Lon1); Lon2 := DegToRad(Lon2);
  y := Sin(Lon2 - Lon1) * Cos(Lat2);
  x := Cos(Lat1) * Sin(Lat2) - Sin(Lat1) * Cos(Lat2) * Cos(Lon2 - Lon1);
  Result := RadToDeg(ArcTan2(y, x));
  if Result < 0 then Result := Result + 360;
end;

function TOctailyWorldleGenerator.GetDirection(Bearing: Double): string;
begin
  if (Bearing >= 337.5) or (Bearing < 22.5) then Result := 'N'
  else if (Bearing >= 22.5) and (Bearing < 67.5) then Result := 'NE'
  else if (Bearing >= 67.5) and (Bearing < 112.5) then Result := 'E'
  else if (Bearing >= 112.5) and (Bearing < 157.5) then Result := 'SE'
  else if (Bearing >= 157.5) and (Bearing < 202.5) then Result := 'S'
  else if (Bearing >= 202.5) and (Bearing < 247.5) then Result := 'SW'
  else if (Bearing >= 247.5) and (Bearing < 292.5) then Result := 'W'
  else Result := 'NW';
end;

procedure TOctailyWorldleGenerator.GenerateDailyPuzzle;
begin
  Randomize;
  if FCountries.Count > 0 then
    FTargetCountry := FCountries[Random(FCountries.Count)];
  FGameDate := Date;
end;

function TOctailyWorldleGenerator.GetDailyPuzzleJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('target_iso', FTargetCountry.ISO);
end;

function TOctailyWorldleGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  GuessCountry: TCountry;
  NormalizedGuess: string;
  Dist, Bear, Percent: Double;
  Found: Boolean;
begin
  Result := TJSONObject.Create;
  Found := False;
  NormalizedGuess := NormalizeString(AGuess);

  for GuessCountry in FCountries do
  begin
    // Hem normalize edilmiş isme hem de alternatif isimlere (Turkey/Türkiye) bakabiliriz
    if (GuessCountry.Name = NormalizedGuess) or
       ((GuessCountry.ISO = 'TR') and (NormalizedGuess = 'TURKEY')) then
    begin
      Found := True;
      Dist := CalculateDistance(GuessCountry.Lat, GuessCountry.Lon,
                                FTargetCountry.Lat, FTargetCountry.Lon);
      Bear := CalculateBearing(GuessCountry.Lat, GuessCountry.Lon,
                               FTargetCountry.Lat, FTargetCountry.Lon);

      Percent := Max(0, 100 - (Dist / 20000) * 100);

      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('country_name', GuessCountry.OriginalName);
      Result.AddPair('distance', TJSONNumber.Create(Round(Dist)));
      Result.AddPair('direction', GetDirection(Bear));
      Result.AddPair('proximity', TJSONNumber.Create(Round(Percent)));
      Break;
    end;
  end;

  if not Found then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Ülke bulunamadı!');
  end;
end;

end.
