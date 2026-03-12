unit uBaseGenerator;

interface

uses
  System.SysUtils, System.JSON, System.DateUtils;

type
  { Tüm 8 oyunun türetileceği temel (Base) sınıf }
  TOctailyBaseGenerator = class
  protected
    FGameName: string;
    FGameDate: TDate;
  public
    constructor Create(AGameName: string); virtual;

    // 1. Her gece saat 00:00'da çalışıp o günün bulmacasını üretecek
    procedure GenerateDailyPuzzle; virtual; abstract;

    // 2. İstemci (Client) GET isteği attığında bulmacanın JSON halini dönecek
    function GetDailyPuzzleJSON: TJSONObject; virtual; abstract;

    // 3. İstemci (Client) POST ile tahmin gönderdiğinde sonucu hesaplayıp JSON dönecek
    function CheckGuess(AGuess: string): TJSONObject; virtual; abstract;

    property GameName: string read FGameName;
    property GameDate: TDate read FGameDate write FGameDate;
  end;

implementation

constructor TOctailyBaseGenerator.Create(AGameName: string);
begin
  FGameName := AGameName;
  FGameDate := Today; // System.DateUtils'den gelir, bugünün tarihini atar
end;

end.
