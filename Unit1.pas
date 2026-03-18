unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  System.JSON, Horse, uOctailyManager, System.Net.HttpClient,
  System.Net.URLClient, System.Net.HttpClientComponent, Horse.CORS,
  uWordleGenerator, Vcl.Menus, Vcl.ExtCtrls, IOUtils, Data.DB, MemDS, DBAccess,
  Uni, UniProvider, SQLServerUniProvider, SecretConsts;

type
  TForm1 = class(TForm)
    btnStartServer: TButton;
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    MenuItemGosterGizle: TMenuItem;
    MenuItemCikis: TMenuItem;
    UniConnection1: TUniConnection;
    Qry: TUniQuery;
    SQLServerUniProvider1: TSQLServerUniProvider;
    procedure btnStartServerClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure MenuItemGosterGizleClick(Sender: TObject);
    procedure MenuItemCikisClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure LogYaz(Mesaj: string)overload;
    procedure LogYaz(Satirlar: TStrings); overload;
  end;

var
  Form1: TForm1;

implementation

procedure TForm1.LogYaz(Mesaj: string);
var
  LogDosyasi: string;
begin
  System.TMonitor.Enter(Self);
  try
    LogDosyasi := ExtractFilePath(ParamStr(0)) + 'OctailyServer.log';
    try
      TFile.AppendAllText(LogDosyasi, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + Mesaj + sLineBreak);
    except
    end;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

procedure TForm1.LogYaz(Satirlar: TStrings);
var
  LogDosyasi, TarihDamgasi, LogIcerik: string;
  I: Integer;
begin
  if Satirlar.Count = 0 then
    Exit;

  LogDosyasi := ExtractFilePath(ParamStr(0)) + 'OctailyServer.log';
  TarihDamgasi := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ';
  LogIcerik := '';

  for I := 0 to Satirlar.Count - 1 do
  begin
    LogIcerik := LogIcerik + TarihDamgasi + Satirlar[I] + sLineBreak;
  end;

  try
    TFile.AppendAllText(LogDosyasi, LogIcerik);
  except
  end;
end;

{$R *.dfm}

procedure TForm1.btnStartServerClick(Sender: TObject);
begin
  if THorse.IsRunning then
  begin
    ShowMessage('Sunucu zaten çalışıyor!');
    Exit;
  end;

  THorse.Use(CORS);

  // --- ROUTE 1: GÜNLÜK BULMACAYI GETİR ---
  THorse.Get('/api/game/:name',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      GameName: string;
      JSONResponse: TJSONObject;
    begin
      GameName := Req.Params['name'];
      JSONResponse := TOctailyManager.Instance.GetPuzzle(GameName);
      try
        Res.Send(JSONResponse.ToJSON).ContentType('application/json');
      finally
        JSONResponse.Free;
      end;
    end);

  // --- ROUTE 2: TAHMİN GÖNDER VE KONTROL ET ---
  THorse.Post('/api/guess/:name',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      GameName, GuessData: string;
      JSONResponse: TJSONObject;
    begin
      GameName := Req.Params['name'];
      GuessData := Req.Body;

      JSONResponse := TOctailyManager.Instance.PostGuess(GameName, GuessData);
      try
        Res.Send(JSONResponse.ToJSON).ContentType('application/json');
      finally
        JSONResponse.Free;
      end;
    end);

  // --- ROUTE 3: (YENİ) GÜNLÜK CEVABI GETİR (GÜVENLİ VE THREAD-SAFE) ---
  THorse.Get('/api/fetch_answer/:name/:uid',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      GameName: string;
      UserID: Integer;
      JSONResponse: TJSONObject;
      HasPlayedToday: Boolean;
      LQuery: TUniQuery;
    begin
      GameName := Req.Params['name'];
      UserID := StrToIntDef(Req.Params['uid'], 0);
      HasPlayedToday := False;

      System.TMonitor.Enter(Form1.UniConnection1);
      try
        LQuery := TUniQuery.Create(nil);
        try
          LQuery.Connection := Form1.UniConnection1;
          // SİHİRLİ DOKUNUŞ: GETDATE() DEĞİL NOW KULLANIYORUZ Kİ SAAT DİLİMİ (TIMEZONE) ŞAŞMASIN!
         LQuery.SQL.Text := 'SELECT 1 FROM daily_scores WHERE user_id = :uid AND game_type = :gt AND CAST(puzzle_date AS DATE) = CAST(GETDATE() AS DATE)';
          LQuery.ParamByName('uid').AsInteger := UserID;
          LQuery.ParamByName('gt').AsString := GameName;
          //LQuery.ParamByName('td').AsDateTime := Now;
          LQuery.Open;
          HasPlayedToday := not LQuery.IsEmpty;
        finally
          LQuery.Free;
        end;
      finally
        System.TMonitor.Exit(Form1.UniConnection1);
      end;

      JSONResponse := TJSONObject.Create;
      try
        if HasPlayedToday then
        begin
          JSONResponse.AddPair('success', TJSONBool.Create(True));
          JSONResponse.AddPair('answer', TOctailyManager.Instance.GetAnswer(GameName));
        end
        else
        begin
          JSONResponse.AddPair('success', TJSONBool.Create(False));
          JSONResponse.AddPair('error', '');
        end;

        Res.Send(JSONResponse.ToJSON).ContentType('application/json');
      finally
        JSONResponse.Free;
      end;
    end);

  // --- SUNUCUYU AYAĞA KALDIR ---
  THorse.Listen(9000,
    procedure
    begin
      TThread.Synchronize(nil,
        procedure
        begin
          Memo1.Lines.Add('Octaily API Sunucusu Başladı! #######');
          Memo1.Lines.Add('9000 portundan dinleniyor.');
          LogYaz(Memo1.Lines);
          btnStartServer.Enabled := False;
        end);
    end);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.Lines.Add('');
  Memo1.Lines.Add('=== Bugünün Cevapları === (' + DateToStr(Now) + ')');
  Memo1.Lines.Add('Wordle TR Cevabı: ' + TOctailyManager.Instance.GetAnswer('wordle_tr'));
  Memo1.Lines.Add('------------------');
  Memo1.Lines.Add('Wordle EN Cevabı: ' + TOctailyManager.Instance.GetAnswer('wordle_en'));
  Memo1.Lines.Add('------------------');
  Memo1.Lines.Add('Sudoku Cevabı: ' + TOctailyManager.Instance.GetAnswer('sudoku'));
  Memo1.Lines.Add('------------------');
  Memo1.Lines.Add('Queens Cevabı: ' + TOctailyManager.Instance.GetAnswer('queens'));
  Memo1.Lines.Add('------------------');
  Memo1.Lines.Add('Nerdle Cevabı: ' + TOctailyManager.Instance.GetAnswer('nerdle'));
  Memo1.Lines.Add('------------------');
  Memo1.Lines.Add('Zip Cevabı: ' + TOctailyManager.Instance.GetAnswer('zip'));
  Memo1.Lines.Add('------------------');
  Memo1.Lines.Add('Hexle Cevabı: ' + TOctailyManager.Instance.GetAnswer('hexle'));
  Memo1.Lines.Add('------------------');
  Memo1.Lines.Add('Worldle Cevabı: ' + TOctailyManager.Instance.GetAnswer('worldle'));
  Memo1.Lines.Add('------------------');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Halt;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
  btnStartServerClick(Self);
  Button1Click(Self);

  UniConnection1.Username := DB_USERNAME;
  UniConnection1.Password := DB_PASS;
  UniConnection1.Connect;
end;

procedure TForm1.MenuItemCikisClick(Sender: TObject);
begin
  Button2Click(Self);
end;

procedure TForm1.MenuItemGosterGizleClick(Sender: TObject);
begin
  if Form1.Visible then
  begin
    Form1.Hide;
    MenuItemGosterGizle.Caption := 'Konsolu Göster';
  end
  else
  begin
    Form1.Show;
    MenuItemGosterGizle.Caption := 'Konsolu Gizle';
  end;
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  MenuItemGosterGizleClick(Self);
end;

end.
