unit uNerdleGenerator;

interface

uses
  System.SysUtils, System.JSON, System.Math, System.Generics.Collections, uBaseGenerator;

type
  TOctailyNerdleGenerator = class(TOctailyBaseGenerator)
  private
    const TARGET_LEN = 8; // Burayı 8 yaptığında her şey otomatik düzelir
  private
    FDailyEquation: string;
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

function TOctailyNerdleGenerator.Evaluate(AExpr: string): Integer;
var
  LPos: Integer;
begin
  AExpr := Trim(AExpr);
  if AExpr = '' then Exit(0);

  // İşlem Önceliği (Sondan başa tarar ki işlem önceliği doğru çalışsın)
  LPos := LastDelimiter('+-', AExpr);
  if LPos > 0 then
  begin
    if AExpr[LPos] = '+' then
      Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) + Evaluate(Copy(AExpr, LPos + 1, MaxInt)))
    else
      Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) - Evaluate(Copy(AExpr, LPos + 1, MaxInt)));
  end;

  LPos := LastDelimiter('*/', AExpr);
  if LPos > 0 then
  begin
    if AExpr[LPos] = '*' then
      Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) * Evaluate(Copy(AExpr, LPos + 1, MaxInt)))
    else
    begin
      try
        if Evaluate(Copy(AExpr, LPos + 1, MaxInt)) = 0 then Exit(-999999);
        Exit(Evaluate(Copy(AExpr, 1, LPos - 1)) div Evaluate(Copy(AExpr, LPos + 1, MaxInt)));
      except
        Exit(-999999);
      end;
    end;
  end;
  Result := StrToIntDef(AExpr, 0);
end;

function TOctailyNerdleGenerator.HasLeadingZeros(AExpr: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to Length(AExpr) - 1 do
    if (AExpr[I] = '0') and ((I = 1) or (CharInSet(AExpr[I-1], ['+', '-', '*', '/']))) then
      if CharInSet(AExpr[I+1], ['0'..'9']) then Exit(True);
end;

function TOctailyNerdleGenerator.IsValidSyntax(AExpr: string): Boolean;
begin
  Result := (AExpr <> '') and (not HasLeadingZeros(AExpr));
end;

procedure TOctailyNerdleGenerator.GenerateDailyPuzzle;
var
  v1, v2, v3, res: Integer;
  op1, op2: Char;
  tempEq: string;
  isValid: Boolean;
const
  Ops: array[0..3] of Char = ('+', '-', '*', '/');
begin
  Randomize;
  isValid := False;

  repeat
    // Akıllı Seçim: Eğer hedef 8 karakterse tek operatörlü denklemlere ağırlık ver
    if (TARGET_LEN <= 8) or (Random(10) > 7) then
    begin
      v1 := Random(900) + 1;
      v2 := Random(100) + 1;
      op1 := Ops[Random(4)];

      case op1 of
        '+': res := v1 + v2;
        '-': res := v1 - v2;
        '*': res := v1 * v2;
        '/': if (v2 <> 0) and (v1 mod v2 = 0) then res := v1 div v2 else Continue;
      end;
      tempEq := IntToStr(v1) + op1 + IntToStr(v2) + '=' + IntToStr(res);
    end
    else
    begin
      // 10-12 karakter için çift operatörlü şablon
      v1 := Random(50) + 1;
      v2 := Random(20) + 1;
      v3 := Random(10) + 1;
      op1 := Ops[Random(4)];
      op2 := Ops[Random(4)];
      tempEq := IntToStr(v1) + op1 + IntToStr(v2) + op2 + IntToStr(v3);
      res := Evaluate(tempEq);
      tempEq := tempEq + '=' + IntToStr(res);
    end;

    if (res >= 0) and (Length(tempEq) = TARGET_LEN) and (not HasLeadingZeros(tempEq)) then
      isValid := True;

  until isValid;

  FDailyEquation := tempEq;
  FGameDate := Date;
end;

function TOctailyNerdleGenerator.GetDailyPuzzleJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('game', FGameName);
  Result.AddPair('length', TJSONNumber.Create(TARGET_LEN));
end;

function TOctailyNerdleGenerator.CheckGuess(AGuess: string): TJSONObject;
var
  JSONArray: TJSONArray;
  LetterObj: TJSONObject;
  I, J: Integer;
  TargetMatched, GuessMatched: array[1..TARGET_LEN] of Boolean;
  Statuses: array[1..TARGET_LEN] of string;
  Parts: TArray<string>;
begin
  Result := TJSONObject.Create;
  Result.AddPair('game', FGameName);

  if Length(AGuess) <> TARGET_LEN then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Uzunluk hatasi!');
    Exit;
  end;

  Parts := AGuess.Split(['=']);
  if (Length(Parts) <> 2) or (not IsValidSyntax(Parts[0])) or
     (Evaluate(Parts[0]) <> StrToIntDef(Parts[1], -999999)) then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('error', 'Matematiksel hata!');
    Exit;
  end;

  Result.AddPair('success', TJSONBool.Create(True));
  JSONArray := TJSONArray.Create;
  for I := 1 to TARGET_LEN do
  begin
    TargetMatched[I] := False;
    GuessMatched[I] := False;
    Statuses[I] := 'absent';
  end;

  for I := 1 to TARGET_LEN do
    if AGuess[I] = FDailyEquation[I] then
    begin
      Statuses[I] := 'correct';
      TargetMatched[I] := True;
      GuessMatched[I] := True;
    end;

  for I := 1 to TARGET_LEN do
    if not GuessMatched[I] then
      for J := 1 to TARGET_LEN do
        if (not TargetMatched[J]) and (AGuess[I] = FDailyEquation[J]) then
        begin
          Statuses[I] := 'present';
          TargetMatched[J] := True;
          Break;
        end;

  for I := 1 to TARGET_LEN do
  begin
    LetterObj := TJSONObject.Create;
    LetterObj.AddPair('char', AGuess[I]);
    LetterObj.AddPair('status', Statuses[I]);
    JSONArray.AddElement(LetterObj);
  end;
  Result.AddPair('result', JSONArray);
end;

end.
