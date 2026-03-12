unit uNerdleGenerator;

interface

uses
  System.SysUtils, System.JSON, System.Math, System.Generics.Collections, uBaseGenerator;

type
  TOctailyNerdleGenerator = class(TOctailyBaseGenerator)
  private
    FDailyEquation: string;
    // Matematiksel yardımcılar
    function Evaluate(AExpr: string): Integer;
    function IsValidSyntax(AExpr: string): Boolean;
    function HasLeadingZeros(AExpr: string): Boolean;
  public
    constructor Create(AGameName: string); reintroduce;
    procedure GenerateDailyPuzzle; override;
    function GetDailyPuzzleJSON: TJSONObject; override;
    function CheckGuess(AGuess: string): TJSONObject; override;

    property DailyEquation: string read FDailyEquation;
  end;

implementation

{ TOctailyNerdleGenerator }

constructor TOctailyNerdleGenerator.Create(AGameName: string);
begin
  inherited Create(AGameName);
end;

{ Basit bir matematiksel ifadeyi hesaplar (Sadece +, -, *, /) }
function TOctailyNerdleGenerator.Evaluate(AExpr: string): Integer;
var
  LPos: Integer;
begin
  // Bu fonksiyon basitliği korumak adına temel işlemleri yapar.
  // Gerçek Nerdle'da işlem önceliği (Çarpma/Bölme önce gelir) vardır.

  // Örnek: "10+5*2" -> Önce çarpmayı bulup ayırmalıyız.
  // Not: Profesyonel bir Parser yerine temel kuralları işletiyoruz.

  AExpr := Trim(AExpr);
  if AExpr = '' then Exit(0);

  // İşlem Önceliği: Toplama ve Çıkarma en son yapılır
  LPos := LastDelimiter('+-', AExpr);
  if LPos > 0 then
  begin
    if AExpr[LPos] = '+' then
      Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) + Evaluate(Copy(AExpr, LPos + 1, MaxInt)))
    else
      Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) - Evaluate(Copy(AExpr, LPos + 1, MaxInt)));
  end;

  // İşlem Önceliği: Çarpma ve Bölme
  LPos := LastDelimiter('*/', AExpr);
  if LPos > 0 then
  begin
    if AExpr[LPos] = '*' then
      Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) * Evaluate(Copy(AExpr, LPos + 1, MaxInt)))
    else
    begin
      // Bölme işlemi (Sıfıra bölme kontrolü)
      try
        Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) div Evaluate(Copy(AExpr, LPos + 1, MaxInt)));
      except
        Exit(-999999); // Hatalı bölme
      end;
    end;
  end;

  Result := StrToIntDef(AExpr, 0);
end;

{ Nerdle kuralı: Sayılar 0 ile başlayamaz (Tek başına 0 hariç) }
function TOctailyNerdleGenerator.HasLeadingZeros(AExpr: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to Length(AExpr) - 1 do
  begin
    // Eğer bir rakam 0 ise ve kendinden önceki karakter bir operatörse (veya başlangıçsa)
    // ve kendinden sonraki karakter bir rakamsa -> Leading Zero vardır.
    if (AExpr[I] = '0') and ((I = 1) or (CharInSet(AExpr[I-1], ['+', '-', '*', '/']))) then
      if CharInSet(AExpr[I+1], ['0'..'9']) then
        Exit(True);
  end;
end;

function TOctailyNerdleGenerator.IsValidSyntax(AExpr: string): Boolean;
begin
  // Boşluk, yanyana operatör kontrolü vb.
  Result := (AExpr <> '') and (not HasLeadingZeros(AExpr));
end;

procedure TOctailyNerdleGenerator.GenerateDailyPuzzle;
var
  Num1, Num2, Res: Integer;
  Ops: array[0..3] of string;
  TempEq: string;
begin
  Randomize;
  Ops[0] := '+'; Ops[1] := '-'; Ops[2] := '*'; Ops[3] := '/';

  // 8 karakterlik geçerli bir denklem bulana kadar deniyoruz
  repeat
    Num1 := Random(90) + 10; // 10-99 arası
    Num2 := Random(90) + 10;
    Res := Num1 + Num2; // Basit bir toplama şablonu
    TempEq := IntToStr(Num1) + '+' + IntToStr(Num2) + '=' + IntToStr(Res);
  until Length(TempEq) = 8;

  FDailyEquation := TempEq;
  FGameDate := Date;
end;

function TOctailyNerdleGenerator.GetDailyPuzzleJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('length', TJSONNumber.Create(8));
  Result.AddPair('allowed_chars', '0123456789+-*/=');
end;

function TOctailyNerdleGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  JSONArray: TJSONArray;
  LetterObj: TJSONObject;
  I, J: Integer;
  TargetMatched, GuessMatched: array[1..8] of Boolean;
  Statuses: array[1..8] of string;
  Parts: TArray<string>;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));

  // 1. Validasyon: Matematiksel doğruluk kontrolü
  Parts := AGuess.Split(['=']);
  if (Length(Parts) <> 2) or (not IsValidSyntax(Parts[0])) or
     (Evaluate(Parts[0]) <> StrToIntDef(Parts[1], -999999)) then
  begin
    Result.AddPair('error', 'Geçersiz matematiksel denklem!');
    Exit;
  end;

  // 2. Renk Algoritması (Wordle ile aynı mantık)
  JSONArray := TJSONArray.Create;
  for I := 1 to 8 do
  begin
    TargetMatched[I] := False;
    GuessMatched[I] := False;
    Statuses[I] := 'absent';
  end;

  for I := 1 to 8 do
    if AGuess[I] = FDailyEquation[I] then
    begin
      Statuses[I] := 'correct';
      TargetMatched[I] := True;
      GuessMatched[I] := True;
    end;

  for I := 1 to 8 do
    if not GuessMatched[I] then
      for J := 1 to 8 do
        if (not TargetMatched[J]) and (AGuess[I] = FDailyEquation[J]) then
        begin
          Statuses[I] := 'present';
          TargetMatched[J] := True;
          Break;
        end;

  for I := 1 to 8 do
  begin
    LetterObj := TJSONObject.Create;
    LetterObj.AddPair('char', AGuess[I]);
    LetterObj.AddPair('status', Statuses[I]);
    JSONArray.AddElement(LetterObj);
  end;

  Result.AddPair('result', JSONArray);
end;

end.
