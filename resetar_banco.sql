-- resetar_banco.sql
-- Rode UMA vez depois do script_banco.sql. Pode rodar de novo sem problema (recria a procedure).
-- Para usar: CALL resetar_banco();  (APAGA todos os dados, mantém as tabelas)

USE alistamento_militar;
DROP PROCEDURE IF EXISTS resetar_banco;
DELIMITER //

CREATE PROCEDURE resetar_banco()
BEGIN
    -- Desliga temporariamente a verificação de chaves estrangeiras
    SET FOREIGN_KEY_CHECKS = 0;

    -- Tabelas "filhas" primeiro (as que têm FK apontando pra outras)
    TRUNCATE TABLE Documento;
    TRUNCATE TABLE Agendamento;
    TRUNCATE TABLE AvaliacaoMedica;
    TRUNCATE TABLE PedidoSenha;

    -- Depois a tabela intermediária
    TRUNCATE TABLE Alistamento;

    -- Por último, as tabelas "pai"
    TRUNCATE TABLE Usuario;
    TRUNCATE TABLE Administrador;
    TRUNCATE TABLE Medico;
    TRUNCATE TABLE Local;
    TRUNCATE TABLE TipoDocumento;

    -- Reativa a verificação de integridade referencial
    SET FOREIGN_KEY_CHECKS = 1;
END //

DELIMITER ;
