unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  System.JSON, Horse, uOctailyManager, System.Net.HttpClient,
  System.Net.URLClient, System.Net.HttpClientComponent, Horse.CORS,
  uWordleGenerator;

type
  TForm1 = class(TForm)
    btnStartServer: TButton;
    Memo1: TMemo;
    Button1: TButton; // İstekleri veya durumu loglamak istersen
    procedure btnStartServerClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnStartServerClick(Sender: TObject);
begin
  // Eğer sunucu zaten çalışıyorsa tekrar başlatmayı engelle
  if THorse.IsRunning then
  begin
    ShowMessage('Sunucu zaten çalışıyor!');
    Exit;
  end;
  THorse.Use(CORS);
  // --- ROUTE 1: GÜNLÜK BULMACAYI GETİR ---
  // Tarayıcıdan veya mobilden oyun istendiğinde bu blok çalışır
  THorse.Get('/api/game/:name',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      GameName: string;
      JSONResponse: TJSONObject;
    begin
      GameName := Req.Params['name']; // URL'den oyun adını al

      JSONResponse := TOctailyManager.Instance.GetPuzzle(GameName);
      try
        Res.Send(JSONResponse.ToJSON).ContentType('application/json');
      finally
        JSONResponse.Free;
      end;
    end);

  // --- ROUTE 2: TAHMİN GÖNDER VE KONTROL ET ---
  // Kullanıcı kelime, koordinat veya JSON gönderdiğinde bu blok çalışır
  THorse.Post('/api/guess/:name',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      GameName, GuessData: string;
      JSONResponse: TJSONObject;
    begin
      GameName := Req.Params['name'];
      GuessData := Req.Body; // Gönderilen veriyi al

      JSONResponse := TOctailyManager.Instance.PostGuess(GameName, GuessData);
      try
        Res.Send(JSONResponse.ToJSON).ContentType('application/json');
      finally
        JSONResponse.Free;
      end;
    end);

  // --- SUNUCUYU AYAĞA KALDIR ---
  // 9000 portundan dinlemeye başlıyoruz
  THorse.Listen(9000,
    procedure
    begin
      // Bu kısım sunucu başarıyla başladığında tetiklenir
      TThread.Synchronize(nil,
        procedure
        begin
          Memo1.Lines.Add('Octaily API Sunucusu Başladı!');
          Memo1.Lines.Add('9000 portundan dinleniyor.');
          Memo1.Lines.Add('Test için tarayıcıda şunu açın:');
          Memo1.Lines.Add('http://localhost:9000/api/game/wordle_tr');
          btnStartServer.Enabled := False; // Yanlışlıkla tekrar basılmasın
        end);
    end);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.Lines.Add('=== Bugünün Cevapları ===');

  Memo1.Lines.Add('Wordle TR Cevabı: ' + TOctailyManager.Instance.GetAnswer
    ('wordle_tr'));
  Memo1.Lines.Add('------------------');

  Memo1.Lines.Add('Wordle EN Cevabı: ' + TOctailyManager.Instance.GetAnswer
    ('wordle_en'));
  Memo1.Lines.Add('------------------');

  Memo1.Lines.Add('Sudoku Cevabı: ' + TOctailyManager.Instance.GetAnswer
    ('sudoku'));
  Memo1.Lines.Add('------------------');

  Memo1.Lines.Add('Queens Cevabı: ' + TOctailyManager.Instance.GetAnswer
    ('queens'));
  Memo1.Lines.Add('------------------');

  Memo1.Lines.Add('Nerdle Cevabı: ' + TOctailyManager.Instance.GetAnswer
    ('nerdle'));
  Memo1.Lines.Add('------------------');

  Memo1.Lines.Add('Zip Cevabı: ' + TOctailyManager.Instance.GetAnswer('zip'));
  Memo1.Lines.Add('------------------');

  Memo1.Lines.Add('Hexle Cevabı: ' + TOctailyManager.Instance.GetAnswer
    ('hexle'));
  Memo1.Lines.Add('------------------');

  Memo1.Lines.Add('Worldle Cevabı: ' + TOctailyManager.Instance.GetAnswer
    ('worldle'));
  Memo1.Lines.Add('------------------');

end;

end.
