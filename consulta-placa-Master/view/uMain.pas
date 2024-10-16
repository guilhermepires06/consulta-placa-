unit uMain;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                   OLA ESTA � UMA API DE CONSULTAR PLACA                                                                            ////
///                   PRIMEIRAMENTE VOCE TEM QUE FAZER UMA CONTA NO https://plataforma.apibrasil.com.br/                              ////
///                   VOCE TEM APROXIMADAMENTE 30 DIAS FREE E 100 CONSULTAS NO MES SENDO ASSIM SERIA LEGAL FAZER UM PLANO            ////
///                   A API QUE ESTOU USANDO NESTE EXEMPLO � A API Placa Dados Free                                                 ////
///               *** PARA MAIS INFORMA��O https://github.com/guilhermepires06                                                     ////
///                                                                                                                               ////
///                                                                                                                              ////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
interface

uses IdTCPConnection, IdTCPClient, IdHTTP, IdBaseComponent, IdComponent,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  Vcl.StdCtrls, Vcl.Controls, Vcl.ExtCtrls, System.Classes,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics,
   Vcl.Forms, Vcl.Dialogs, MaskUtils, ShellApi, System.JSON,StrUtils,  IdStack, IdStackConsts,
   WinInet, IpPeerClient, Vcl.Buttons,  Data.DB , ToolWin , Vcl.Grids, Vcl.DBGrids, Vcl.ComCtrls,
  IdServerIOHandler, REST.Types, Data.Bind.Components, Data.Bind.ObjectScope,
  REST.Client, REST.Authenticator.Basic, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.NetEncoding, IdAuthenticationDigest, IdGlobal, REST.Response.Adapter,
  VCLTee.TeCanvas;

type
  TfrmMain = class(TForm)
    Marca: TLabeledEdit;
    Municipio: TLabeledEdit;
    Renavam: TLabeledEdit;
    Modelo: TLabeledEdit;
    Chassi: TLabeledEdit;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    IdHTTP1: TIdHTTP;
    Cor: TLabeledEdit;
    Combustivel: TLabeledEdit;
    Status: TEdit;
    LBSTATUS: TLabel;
    AnoModelo: TEdit;
    UF: TEdit;
    ValorFipe: TEdit;
    Label1: TLabel;
    nacionalidade: TEdit;
    Label3: TLabel;
    situacao: TEdit;
    Label4: TLabel;
    Label2: TLabel;
    restricao: TEdit;
    MemoLog: TMemo;
    Label5: TLabel;
    Ano: TEdit;
    Label6: TLabel;
    Clear: TButton;
    btnConsultar: TBitBtn;
    token: TEdit;
    Label7: TLabel;
    edtPlaca: TEdit;
    Label8: TLabel;
    procedure btnConsultarClick(Sender: TObject);
    procedure conectarClick(Sender: TObject);
    procedure MemoLogChange(Sender: TObject);
    procedure ClearClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);


  private
      { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}


procedure TfrmMain.conectarClick(Sender: TObject);
var
  IdHTTP: TIdHTTP;
  JSONRequest, JSONResponse: TStringStream;
  URL, Body: string;
  LoginData: TJSONObject;
begin
  IdHTTP := TIdHTTP.Create(nil);
  JSONRequest := TStringStream.Create;
  JSONResponse := TStringStream.Create;

  try
    URL := 'https://cluster.apigratis.com/api/v1/login';    // Link para fazer a autentica��o
                                                           // cria a autentica��o, essa autentica��o nao muda
    LoginData := TJSONObject.Create;
    LoginData.AddPair('email', 'SEU USUARIO AQUI');
    LoginData.AddPair('password', 'SUA SENHA AQUI');
    JSONRequest.WriteString(LoginData.ToString);

      //monta o json

    IdHTTP.Request.ContentType := 'application/json';
    IdHTTP.Post(URL, JSONRequest, JSONResponse);


    try
      if Assigned(JSONResponse) then
      begin
        LoginData := TJSONObject.ParseJSONValue(JSONResponse.DataString) as TJSONObject;
        if Assigned(LoginData) then
        begin
          if LoginData.TryGetValue('message', Body) then
            status.Text := Body;
          LoginData.Free;
        end;
      end;
    except
      on E: Exception do
        ShowMessage('Erro ao extrair mensagem do JSON: ' + E.Message);
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao fazer login: ' + E.Message);
  end;

  JSONRequest.Free;
  JSONResponse.Free;
  IdHTTP.Free;
end;

procedure TfrmMain.btnConsultarClick(Sender: TObject);
var
  http: TIdHTTP;
  ioHandler: TIdSSLIOHandlerSocketOpenSSL;
  request: TIdHTTPRequest;
  response: string;
  requestBody: TStringStream;
  Confirma: Integer;
begin
  if edtPlaca.Text = EmptyStr then                                              // Faz a pergunta se realmente � esta placa que deseja comprar
    Exit;

  Confirma := MessageDlg('Deseja realmente consultar a placa ' + edtPlaca.Text + ' ?', mtConfirmation, [mbYes, mbNo], 0);
  if Confirma = mrNo then
    Exit;

  btnConsultar.Caption :=  ' Consultando. Aguarde... ';
  btnConsultar.Repaint;

  http := TIdHTTP.Create(nil);
  ioHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  request := TIdHTTPRequest.Create(nil);
  requestBody := TStringStream.Create;

  try
    http.IOHandler := ioHandler;
    http.Request.ContentType := 'application/json';
    http.Request.CustomHeaders.AddValue('SecretKey', 'SecretKey');           // VAI TER NA SUA CONTA
    http.Request.CustomHeaders.AddValue('PublicToken', 'PublicToken');       // VAI TER NA SUA CONTA
    http.Request.CustomHeaders.AddValue('DeviceToken', token.Text);             // este Tokem tem que cadastrar na plataforma junto com o ip do cliente
    http.Request.CustomHeaders.AddValue('Authorization', 'Bearer '); // SAO 360 CARACTERES ESTAO TEM QUE COLOCAR UM + NO MEIO

    requestBody.WriteString('{"placa":"' + edtPlaca.Text + '"}');

    response := http.Post('https://cluster.apigratis.com/api/v1/vehicles/dados', requestBody);

    MemoLog.Lines.Text := response;
  except
    on E: Exception do
    begin
      ShowMessage('Erro: ' + E.Message);
    end;
  end;

  btnConsultar.Caption := '       Consultar Placa          ';

end;


////////////////PEGANDO OS DADOS DO JSON E COLOCANDO NO MEUS CAMPOS ADEQUADAMENTE//////////
procedure TfrmMain.MemoLogChange(Sender: TObject);
var
  JSONString: string;
  JSONObject: TJSONObject;
  ResponseObject: TJSONObject;
  ExtraObject: TJSONObject;
  CombustivelObject: TJSONObject;
  CombustivelValue: TJSONValue;
  MunicipioValue: TJSONValue;
  UFValue: TJSONValue;
  ChassiValue: TJSONValue;
  CorValue: TJSONValue;
  AnoValue: TJSONValue;
  AnoObject: TJSONObject;
  AnoModeloValue: TJSONValue;
  FipeObject: TJSONObject;
  DadosArray: TJSONArray;
  DadosObject: TJSONObject;
  ValorFipeValue: TJSONValue;
  OrigemValue: TJSONValue;
  SituacaoValue: TJSONValue;
  RestricaoObject: TJSONObject;
  RestricaoValue: TJSONValue;
begin

  if MemoLog.Lines.Count = 0 then                                        // Verificar se o MemoLog est� vazio
    Exit;
  JSONString := MemoLog.Lines.Text;                                     // Obter a string JSON do MemoLog
  JSONObject := TJSONObject.ParseJSONValue(JSONString) as TJSONObject; // Fazer o parsing do JSON

  try
    if Assigned(JSONObject) then
    begin

      ResponseObject := JSONObject.GetValue('response') as TJSONObject;   // Obter o objeto "response" do JSON
      if Assigned(ResponseObject) then
      begin

        ExtraObject := ResponseObject.GetValue('extra') as TJSONObject;
        if Assigned(ExtraObject) then
        begin

          ChassiValue := ExtraObject.GetValue('chassi');                  // Obter o valor da tag "chassi" dentro do objeto "extra"
          if Assigned(ChassiValue) then
          begin

            Chassi.Text := ChassiValue.Value;
          end;


          CombustivelObject := ExtraObject.GetValue('combustivel') as TJSONObject;
          if Assigned(CombustivelObject) then
          begin

            CombustivelValue := CombustivelObject.GetValue('combustivel');      // Obter o valor da tag "combustivel" dentro do objeto "combustivel"
            if Assigned(CombustivelValue) then
            begin

              Combustivel.Text := CombustivelValue.Value;
            end;
          end;

          Renavam.Text := ExtraObject.GetValue('renavam').Value;                // Obter o valor da tag "renavam" dentro do objeto "extra"


          RestricaoObject := ExtraObject.GetValue('restricao_1') as TJSONObject;// Obter o objeto "restricao" dentro do objeto "extra"
          if Assigned(RestricaoObject) then
          begin
            RestricaoValue := RestricaoObject.GetValue('restricao');
            if Assigned(RestricaoValue) then
            begin
              Restricao.Text := RestricaoValue.Value;
            end;
          end;
        end;


        OrigemValue := ResponseObject.GetValue('origem');                       // Obter o valor da tag "origem" do JSON
        if Assigned(OrigemValue) then
        begin
          nacionalidade.Text := OrigemValue.Value;
        end;


        SituacaoValue := ResponseObject.GetValue('situacao');                   // Obter o valor da tag "situacao" do JSON
        if Assigned(SituacaoValue) then
        begin
          Situacao.Text := SituacaoValue.Value;
        end;



        AnoValue := ResponseObject.GetValue('ano');                             // Obter o valor da tag "ano" do JSON
        if Assigned(AnoValue) then
        begin
          Ano.Text := AnoValue.Value;
        end;




        AnoModeloValue := ResponseObject.GetValue('anoModelo');                 // Obter o valor da tag "anoModelo" do JSON
        if Assigned(AnoModeloValue) then
        begin
          AnoModelo.Text := AnoModeloValue.Value;
        end;


        MunicipioValue := ResponseObject.GetValue('municipio');                 // Obter o valor da tag "municipio" do JSON
        if Assigned(MunicipioValue) then
        begin
          Municipio.Text := MunicipioValue.Value;
        end;
        UFValue := ResponseObject.GetValue('uf');                               // Obter o valor da tag "Uf do municipio" do JSON
        if Assigned(UFValue) then
        begin
          UF.Text := '/' + UFValue.Value;
        end;


        CorValue := ResponseObject.GetValue('cor');                             // Obter o valor da tag "cor" dentro do objeto "response" do JSON
        if Assigned(CorValue) then
        begin
          Cor.Text := CorValue.Value;
        end;


        Marca.Text := ResponseObject.GetValue('MARCA').Value;
        Modelo.Text := ResponseObject.GetValue('MODELO').Value;


        FipeObject := ResponseObject.GetValue('fipe') as TJSONObject;           // Obter a Coluna "fipe" do JSON
        if Assigned(FipeObject) then
        begin

          DadosArray := FipeObject.GetValue('dados') as TJSONArray;             // Obter a Culina "Dados" detro da Fipe
          if Assigned(DadosArray) and (DadosArray.Count > 0) then
          begin

            DadosObject := DadosArray.Items[0] as TJSONObject;
            if Assigned(DadosObject) then
            begin
              ValorFipeValue := DadosObject.GetValue('texto_valor');            // Obter a valor da "fipe" do veiculo
              if Assigned(ValorFipeValue) then
              begin
               ValorFipe.Text := ValorFipeValue.Value;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    JSONObject.Free;

  end;
end;





procedure TfrmMain.ClearClick(Sender: TObject);                                 // Pergunta se realmente deseja zerar todos os dados
var
  Confirma: Integer;
begin
  Confirma := MessageDlg('Tem certeza que deseja limpar todos os campos?', mtConfirmation, [mbYes, mbNo], 0);
  if Confirma = mrYes then
  begin

    MemoLog.Clear;
    edtPlaca.Clear;
    Marca.Clear;
    Municipio.Clear;
    Renavam.Clear;
    Modelo.Clear;
    Chassi.Clear;
    Cor.Clear;
    Combustivel.Clear;
    AnoModelo.Clear;
    UF.Clear;
    ValorFipe.Clear;
    nacionalidade.Clear;
    situacao.Clear;
    restricao.Clear;
    Ano.Clear;

    ShowMessage('Campos limpos com sucesso.');
  end;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);      // Pergunta se realmente quer sair do systema
var
  Confirma: Integer;
begin
  Confirma := MessageDlg('Tem certeza que deseja sair?', mtConfirmation, [mbYes, mbNo], 0);
  CanClose := Confirma = mrYes;
end;


procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;


end.

