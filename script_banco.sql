-- =====================================================================
-- script_banco.sql
-- Cria o banco do zero, já com todas as mudanças da versão final:
--   - Usuario: sexo, nacionalidade, consentimento LGPD,
--     CPF/RG/CEP criptografados e cpf_hash (para não repetir CPF)
--   - Documento: arquivo (imagem ou PDF) e tipo do arquivo
--   - Tabela nova: PedidoSenha (recuperação de senha)
-- Para um banco que JÁ EXISTE, use o atualizar_banco_v2.sql.
-- =====================================================================

CREATE DATABASE alistamento_militar;
USE alistamento_militar;

CREATE TABLE Usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    data_nascimento DATE NOT NULL,

    -- Alistamento feminino: o sexo define se o alistamento é obrigatório ou voluntário
    sexo VARCHAR(20) NOT NULL,

    -- Só brasileiros natos ou naturalizados podem se alistar
    nacionalidade VARCHAR(50) NOT NULL,

    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),

    -- CPF, RG e CEP são gravados CRIPTOGRAFADOS pela API (por isso o tamanho maior)
    cpf VARCHAR(255) NOT NULL,

    -- "Impressão digital" (SHA-256) do CPF: como o CPF fica criptografado,
    -- é esta coluna que impede cadastrar o mesmo CPF duas vezes
    cpf_hash VARCHAR(64) NOT NULL UNIQUE,

    nome_pai VARCHAR(100),
    nome_mae VARCHAR(100) NOT NULL,
    estado_civil VARCHAR(20),
    uf CHAR(2),
    escolaridade VARCHAR(50),
    rg VARCHAR(255) NOT NULL,
    local_nascimento VARCHAR(100),
    cep VARCHAR(255),
    bairro VARCHAR(100),
    municipio VARCHAR(100),
    pais_residencia VARCHAR(50),
    zona_residencial VARCHAR(50),
    numero_residencia VARCHAR(10),
    logradouro VARCHAR(150),
    estado VARCHAR(50),

    -- LGPD: aceite da Política de Privacidade no cadastro
    consentimento_lgpd BOOLEAN NOT NULL DEFAULT FALSE,
    data_consentimento DATETIME NULL,

    CONSTRAINT ck_usuario_sexo
        CHECK (sexo IN ('Masculino', 'Feminino')),

    CONSTRAINT ck_usuario_nacionalidade
        CHECK (nacionalidade IN ('Brasileira', 'Brasileira naturalizada'))
);

CREATE TABLE Administrador (
    id_admin INT AUTO_INCREMENT PRIMARY KEY,
    nome_admin VARCHAR(100) NOT NULL,
    email_admin VARCHAR(100) NOT NULL UNIQUE,
    senha_admin VARCHAR(255) NOT NULL
);

CREATE TABLE Alistamento (
    id_alistamento INT AUTO_INCREMENT PRIMARY KEY,
    data_alistamento DATE,
    status VARCHAR(50) DEFAULT 'Aguardando documentos',
    id_usuario INT NOT NULL UNIQUE,
    id_admin INT NULL,

    CONSTRAINT fk_alistamento_usuario
        FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE RESTRICT   -- não deixa deletar usuário com alistamento
        ON UPDATE CASCADE,   -- se o id atualizar, propaga nas outras tabelas

    CONSTRAINT fk_alistamento_admin
        FOREIGN KEY (id_admin) REFERENCES Administrador(id_admin)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE TipoDocumento (
    id_tipo_documento INT AUTO_INCREMENT PRIMARY KEY,
    nome_tipo VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT
);

CREATE TABLE Documento (
    id_documento INT AUTO_INCREMENT PRIMARY KEY,
    numero_documento VARCHAR(50) NOT NULL,
    numero_folha VARCHAR(50),
    numero_livro VARCHAR(50),
    data_emissao DATE NOT NULL,
    orgao_emissor VARCHAR(100) NOT NULL,
    cidade_emissao VARCHAR(100) NOT NULL,
    estado_emissao VARCHAR(50) NOT NULL,
    nome_arquivo VARCHAR(100) NOT NULL,

    -- Arquivo enviado pelo cidadão (imagem JPG/PNG ou PDF, até 5 MB)
    -- e o seu tipo (image/jpeg, image/png ou application/pdf)
    arquivo LONGBLOB NULL,
    tipo_arquivo VARCHAR(100) NULL,

    data_envio DATETIME NOT NULL,
    -- Usada pelo admin pra aprovar/reprovar ('Aprovado'/'Reprovado'/'Em análise')
    status VARCHAR(20) DEFAULT 'Em análise' NOT NULL,
    id_usuario INT NOT NULL,
    id_alistamento INT NOT NULL,
    id_tipo_documento INT NOT NULL,

    CONSTRAINT fk_documento_usuario
        FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_documento_alistamento
        FOREIGN KEY (id_alistamento) REFERENCES Alistamento(id_alistamento)
        ON DELETE RESTRICT   -- não deixa deletar alistamento com documentos
        ON UPDATE CASCADE,

    CONSTRAINT fk_documento_tipo
        FOREIGN KEY (id_tipo_documento) REFERENCES TipoDocumento(id_tipo_documento),

    CONSTRAINT ck_documento_tipo_arquivo
        CHECK (tipo_arquivo IS NULL OR tipo_arquivo IN ('image/jpeg', 'image/png', 'application/pdf'))
);

CREATE TABLE Local (
    id_local INT AUTO_INCREMENT PRIMARY KEY,
    nome_unidade VARCHAR(100) NOT NULL,
    endereco_local VARCHAR(150) NOT NULL,
    cidade_local VARCHAR(100) NOT NULL,
    estado_local VARCHAR(50) NOT NULL,
    cep_local VARCHAR(10) NOT NULL
);

CREATE TABLE Medico (
    id_medico INT AUTO_INCREMENT PRIMARY KEY,
    nome_medico VARCHAR(100) NOT NULL,
    crm VARCHAR(20) NOT NULL UNIQUE,
    especialidade VARCHAR(100),
    telefone_medico VARCHAR(20),
    email_medico VARCHAR(100) NOT NULL UNIQUE,
    senha_medico VARCHAR(255) NOT NULL
);

CREATE TABLE AvaliacaoMedica (
    id_avaliacao INT AUTO_INCREMENT PRIMARY KEY,
    data_avaliacao DATE NOT NULL,
    resultado VARCHAR(100) NOT NULL,
    observacoes TEXT,
    id_alistamento INT NOT NULL UNIQUE,
    id_medico INT NOT NULL,
    id_local INT NOT NULL,

    CONSTRAINT fk_avaliacao_alistamento
        FOREIGN KEY (id_alistamento) REFERENCES Alistamento(id_alistamento)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_avaliacao_medico
        FOREIGN KEY (id_medico) REFERENCES Medico(id_medico),

    CONSTRAINT fk_avaliacao_local
        FOREIGN KEY (id_local) REFERENCES Local(id_local),

    -- Permite apenas os resultados: Apto, Inapto ou Em análise
    CHECK (resultado IN ('Apto', 'Inapto', 'Em análise'))
);

CREATE TABLE Agendamento (
    id_agendamento INT AUTO_INCREMENT PRIMARY KEY,
    data_agendamento DATE NOT NULL,
    horario TIME NOT NULL,
    id_alistamento INT NOT NULL UNIQUE, -- (1,1) cada alistamento tem 1 agendamento
    id_local INT NOT NULL,
    id_medico INT NOT NULL,
    -- Vira true quando o usuário confirma presença
    confirmado BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'Agendado' NOT NULL,

    CONSTRAINT fk_agendamento_alistamento
        FOREIGN KEY (id_alistamento) REFERENCES Alistamento(id_alistamento)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_agendamento_local
        FOREIGN KEY (id_local) REFERENCES Local(id_local),

    CONSTRAINT fk_agendamento_medico
        FOREIGN KEY (id_medico) REFERENCES Medico(id_medico)
);

-- Recuperação de senha (versão simples):
-- o cidadão (ou médico) pede uma nova senha informando o e-mail
-- e o administrador redefine. Não tem chave estrangeira para o usuário
-- de propósito: assim o sistema não revela se o e-mail está cadastrado.
CREATE TABLE PedidoSenha (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    data_conclusao DATETIME NULL,
    -- Administrador que atendeu o pedido
    id_admin INT NULL,

    CONSTRAINT fk_pedido_senha_admin
        FOREIGN KEY (id_admin) REFERENCES Administrador(id_admin)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT ck_pedido_senha_status
        CHECK (status IN ('PENDENTE', 'CONCLUIDO'))
);
