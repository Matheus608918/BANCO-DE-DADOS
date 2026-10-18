-- =====================================================================
-- atualizar_banco_v2.sql
-- Atualiza um banco que JÁ EXISTE para a versão final.
-- Rode UMA vez só, no MySQL Workbench, ANTES de ligar a API nova.
--
-- Recomendado: como os dados atuais são de teste, limpe-os antes com
--   CALL resetar_banco();
-- Motivo: CPF, RG e CEP antigos estão em texto normal, e a API nova espera
-- esses dados criptografados. Se não limpar, os cadastros antigos
-- vão dar erro ao serem lidos pela API.
-- =====================================================================

USE alistamento_militar;
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------
-- 1. Usuario: sexo e nacionalidade (alistamento feminino e nacionalidade)
-- ---------------------------------------------------------------------
ALTER TABLE Usuario
    ADD COLUMN sexo VARCHAR(20) NULL AFTER data_nascimento,
    ADD COLUMN nacionalidade VARCHAR(50) NULL AFTER sexo;

-- Cadastros que já existiam: considerados masculinos e brasileiros
UPDATE Usuario SET sexo = 'Masculino' WHERE sexo IS NULL;
UPDATE Usuario SET nacionalidade = 'Brasileira' WHERE nacionalidade IS NULL;

ALTER TABLE Usuario
    MODIFY sexo VARCHAR(20) NOT NULL,
    MODIFY nacionalidade VARCHAR(50) NOT NULL,
    ADD CONSTRAINT ck_usuario_sexo
        CHECK (sexo IN ('Masculino', 'Feminino')),
    ADD CONSTRAINT ck_usuario_nacionalidade
        CHECK (nacionalidade IN ('Brasileira', 'Brasileira naturalizada'));

-- ---------------------------------------------------------------------
-- 2. Usuario: criptografia de CPF, RG e CEP
-- ---------------------------------------------------------------------
-- A regra "CPF com 11 números" e o UNIQUE do CPF saem, porque o valor
-- criptografado não é mais só números e muda a cada gravação.
-- (se esta linha der erro dizendo que a regra não existe, pode pular)
ALTER TABLE Usuario DROP CONSTRAINT ck_usuario_cpf;
-- (se esta linha der erro dizendo que o índice não existe, pode pular)
ALTER TABLE Usuario DROP INDEX cpf;

ALTER TABLE Usuario
    MODIFY cpf VARCHAR(255) NOT NULL,
    MODIFY rg VARCHAR(255) NOT NULL,
    MODIFY cep VARCHAR(255) NULL,
    ADD COLUMN cpf_hash VARCHAR(64) NULL AFTER cpf;

-- Para cadastros antigos: SHA-256 dos 11 números do CPF
UPDATE Usuario SET cpf_hash = SHA2(cpf, 256) WHERE cpf_hash IS NULL;

ALTER TABLE Usuario
    MODIFY cpf_hash VARCHAR(64) NOT NULL,
    ADD CONSTRAINT uk_usuario_cpf_hash UNIQUE (cpf_hash);

-- ---------------------------------------------------------------------
-- 3. Usuario: consentimento LGPD
-- ---------------------------------------------------------------------
ALTER TABLE Usuario
    ADD COLUMN consentimento_lgpd BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN data_consentimento DATETIME NULL;

-- ---------------------------------------------------------------------
-- 4. Documento: arquivo enviado (imagem ou PDF)
-- ---------------------------------------------------------------------
ALTER TABLE Documento
    ADD COLUMN arquivo LONGBLOB NULL AFTER nome_arquivo,
    ADD COLUMN tipo_arquivo VARCHAR(100) NULL AFTER arquivo,
    ADD CONSTRAINT ck_documento_tipo_arquivo
        CHECK (tipo_arquivo IS NULL OR tipo_arquivo IN ('image/jpeg', 'image/png', 'application/pdf'));

-- ---------------------------------------------------------------------
-- 5. Tabela nova: PedidoSenha (recuperação de senha)
-- ---------------------------------------------------------------------
CREATE TABLE PedidoSenha (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    data_conclusao DATETIME NULL,
    id_admin INT NULL,

    CONSTRAINT fk_pedido_senha_admin
        FOREIGN KEY (id_admin) REFERENCES Administrador(id_admin)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT ck_pedido_senha_status
        CHECK (status IN ('PENDENTE', 'CONCLUIDO'))
);

SET SQL_SAFE_UPDATES = 1;

-- Conferir o resultado
DESCRIBE Usuario;
DESCRIBE Documento;
DESCRIBE PedidoSenha;
