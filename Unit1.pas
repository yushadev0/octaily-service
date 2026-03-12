unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON,
  uBaseGenerator,
  uWordleGenerator;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Edit1: TEdit;
    Label1: TLabel;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
     FWordleGen : TOctailyWordleGenerator;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  GuessJSON: TJSONObject;
begin
  Memo1.Clear;

  if Length(Edit1.Text) <> 5 then
  begin
    ShowMessage('Lütfen 5 harfli bir kelime girin!');
    Exit;
  end;

  // Edit'e yazdığın kelimeyi API'ye gönder!
  GuessJSON := FWordleGen.CheckGuess(Edit1.Text);
  try
    Memo1.Lines.Add('--- TAHMİN SONUCU ---');
    Memo1.Lines.Add(GuessJSON.Format(2));
  finally
    GuessJSON.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  DataPath: string;
begin

  // 1. Form açıldığında motoru 1 kez ayağa kaldır
  DataPath := ExtractFilePath(ParamStr(0)) + 'Data\wordle_tr.txt';
  FWordleGen := TOctailyWordleGenerator.Create('wordle_tr', DataPath);

  // 2. Gece 00:00 simülasyonu: Rastgele kelimeyi üret
  FWordleGen.GenerateDailyPuzzle;

  // 3. Kopya çekmek (test etmek) için Label'a yazdır :)
  Label1.Caption := 'Günün Gizli Kelimesi: ' + FWordleGen.DailyWord;
  Edit1.Text := ''; // Edit'i temizle

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
FWordleGen.Free;
end;

end.
