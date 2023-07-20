-- Drop de todas as Tabelas
DROP TABLE Consulta;
DROP TABLE Treino;
DROP TABLE Basico;
DROP TABLE Premium;
DROP TABLE Gym;
DROP TABLE Gerente;
DROP TABLE Nutricionista;
DROP TABLE PT;
DROP TABLE Servico;
DROP TABLE Cliente;
DROP TABLE Colaborador;
DROP TABLE Pessoa;

-- Create de todas as tabelas
CREATE TABLE Pessoa (
  cc NUMBER PRIMARY KEY NOT NULL,
  nome VARCHAR(100) NOT NULL,
  telefone NUMBER(9) NOT NULL,
  email VARCHAR(100) NOT NULL,
  data_nascimento DATE NOT NULL
);

CREATE TABLE Colaborador (
  cc NUMBER PRIMARY KEY NOT NULL,
  FOREIGN KEY (cc) REFERENCES Pessoa(cc)
);

CREATE TABLE Cliente (
  cc NUMBER PRIMARY KEY NOT NULL,
  FOREIGN KEY (cc) REFERENCES Pessoa(cc)
);

CREATE TABLE Servico (
  idServico NUMBER PRIMARY KEY NOT NULL,
  data DATE NOT NULL,
  hora NUMBER NOT NULL
);

CREATE TABLE PT (
  cc NUMBER PRIMARY KEY NOT NULL,
  certificado NUMBER NOT NULL,
  FOREIGN KEY (cc) REFERENCES Colaborador(cc) ON DELETE CASCADE
);

CREATE TABLE Nutricionista (
  cc NUMBER PRIMARY KEY NOT NULL,
  ordem NUMBER NOT NULL,
  FOREIGN KEY (cc) REFERENCES Colaborador(cc) ON DELETE CASCADE
);

CREATE TABLE Gerente (
  cc NUMBER PRIMARY KEY NOT NULL,
  FOREIGN KEY (cc) REFERENCES Colaborador(cc)
);

CREATE TABLE Gym (
  idGym NUMBER PRIMARY KEY NOT NULL, 
  telemovel NUMBER(9) NOT NULL,
  cidade VARCHAR(100) NOT NULL,
  rua VARCHAR(100) NOT NULL,
  cc NUMBER NOT NULL,
  FOREIGN KEY (cc) REFERENCES Gerente(cc) ON DELETE CASCADE
);

CREATE TABLE Premium (
  cc NUMBER PRIMARY KEY NOT NULL,
  FOREIGN KEY (cc) REFERENCES Cliente(cc)
);

CREATE TABLE Basico (
  cc NUMBER NOT NULL,
  idGym NUMBER NOT NULL,
  FOREIGN KEY (cc) REFERENCES Cliente(cc),
  FOREIGN KEY (idGym) REFERENCES Gym(idGym)
);


CREATE TABLE Treino (
  idServico NUMBER NOT NULL,
  ccPT NUMBER NOT NULL,
  ccPremium NUMBER NOT NULL,
  tipo_treino VARCHAR(100) NOT NULL,
  FOREIGN KEY (idServico) REFERENCES Servico(idServico),
  FOREIGN KEY (ccPT) REFERENCES PT(cc),
  FOREIGN KEY (ccPremium) REFERENCES Premium(cc) ON DELETE CASCADE
);

CREATE TABLE Consulta (
  idServico NUMBER NOT NULL,
  ccNutricionista NUMBER NOT NULL,
  ccCliente NUMBER NOT NULL,
  objetivo VARCHAR(100) NOT NULL,
  FOREIGN KEY (idServico) REFERENCES Servico(idServico),
  FOREIGN KEY (ccNutricionista) REFERENCES Nutricionista(cc),
  FOREIGN KEY (ccCliente) REFERENCES Cliente(cc) ON DELETE CASCADE
);


                                                                       -- VIEW E TRIGGERS DO PT -- 
CREATE OR REPLACE VIEW PTView AS
SELECT cc, certificado, nome, telefone, email, data_nascimento
FROM PT
INNER JOIN Colaborador USING(cc)
INNER JOIN Pessoa USING(cc);


CREATE OR REPLACE TRIGGER adiciona_pt
INSTEAD OF INSERT ON PTView
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
  IF (Exist > 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Já existe uma pessoa com o mesmo id no sistema.');
  ELSE
    INSERT INTO Pessoa 
    VALUES (:new.cc, :new.nome, :new.telefone, :new.email, :new.data_nascimento);
    
    INSERT INTO Colaborador 
    VALUES (:new.cc);
    
    INSERT INTO PT 
    VALUES (:new.cc, :new.certificado);
  END IF;
END;
/

CREATE OR REPLACE TRIGGER remove_pt
INSTEAD OF DELETE ON PTView
DECLARE
  Exist NUMBER;
BEGIN
 SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :old.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    -- Verificar se existem treinos associados ao PT
    SELECT COUNT(*) INTO Exist FROM Treino WHERE ccPT = :old.cc;
    IF (Exist > 0) THEN
      -- Imprimir a mensagem quando houver treinos associados
      RAISE_APPLICATION_ERROR (-20101, 'O PT possui treinos associados. Remova os treinos antes de excluí-lo.');
    END IF;

    -- Remover o PT somente se não houver treinos associados
    IF (Exist = 0) THEN
      DELETE FROM PT WHERE cc = :old.cc;
      DELETE FROM Colaborador WHERE cc = :old.cc;
      DELETE FROM Pessoa WHERE cc = :old.cc;
    END IF;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER edita_pt
INSTEAD OF UPDATE ON PTView
FOR EACH ROW
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    UPDATE Pessoa
    SET cc = :new.cc, nome = :new.nome, telefone = :new.telefone, email = :new.email, data_nascimento = :new.data_nascimento
    WHERE cc = :old.cc;
    
    UPDATE Colaborador
    SET cc = :new.cc
    WHERE cc = :old.cc;
    
    UPDATE PT
    SET cc = :new.cc, certificado = :new.certificado
    WHERE cc = :old.cc;
  END IF;
END;
/
  
                                                                       -- VIEW E TRIGGERS DO NUTRICIONISTA -- 

CREATE OR REPLACE VIEW NutriView AS
SELECT cc, ordem, nome, telefone, email, data_nascimento
FROM Nutricionista
INNER JOIN Colaborador USING(cc)
INNER JOIN Pessoa USING(cc);


CREATE OR REPLACE TRIGGER adiciona_nutri
INSTEAD OF INSERT ON NutriView
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
  IF (Exist > 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Já existe uma pessoa com o mesmo id no sistema.');
  ELSE
    INSERT INTO Pessoa 
    VALUES (:new.cc, :new.nome, :new.telefone, :new.email, :new.data_nascimento);
    
    INSERT INTO Colaborador 
    VALUES (:new.cc);
    
    INSERT INTO Nutricionista 
    VALUES (:new.cc, :new.ordem);
  END IF;
END;
/

CREATE OR REPLACE TRIGGER remove_nutri
INSTEAD OF DELETE ON NutriView
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :old.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    -- Verificar se existem treinos associados ao Nutri
    SELECT COUNT(*) INTO Exist FROM Consulta WHERE ccNutricionista = :old.cc;
    IF (Exist > 0) THEN
      -- Imprimir a mensagem quando houver consultas associadas.
      RAISE_APPLICATION_ERROR (-20101, 'O Nutricionista possui consultas associadas. Remova as consultas antes de excluí-lo.');
    END IF;

    -- Remover o Nutri somente se não houver consultas associadas
    IF (Exist = 0) THEN
      DELETE FROM Nutricionista WHERE cc = :old.cc;
      DELETE FROM Colaborador WHERE cc = :old.cc;
      DELETE FROM Pessoa WHERE cc = :old.cc;
    END IF;
  END IF;
END;
/


CREATE OR REPLACE TRIGGER edita_nutri
INSTEAD OF UPDATE ON NutriView
FOR EACH ROW
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    UPDATE Pessoa
    SET cc = :new.cc, nome = :new.nome, telefone = :new.telefone, email = :new.email, data_nascimento = :new.data_nascimento
    WHERE cc = :old.cc;
    
    UPDATE Colaborador
    SET cc = :new.cc
    WHERE cc = :old.cc;
    
    UPDATE Nutricionista
    SET cc = :new.cc
    WHERE cc = :old.cc;
  END IF;
END;
/


                                                                       -- VIEW E TRIGGERS DO CLIENTE PREMIUM -- 
                                                                       
CREATE OR REPLACE VIEW PremiumView AS
SELECT cc, nome, telefone, email, data_nascimento
FROM Premium
INNER JOIN Cliente USING(cc)
INNER JOIN Pessoa USING(cc);            


CREATE OR REPLACE TRIGGER adiciona_premium
INSTEAD OF INSERT ON PremiumView
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
    
  IF (Exist > 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Já existe uma pessoa com o mesmo id no sistema.');
 
  ELSE
    INSERT INTO Pessoa 
    VALUES (:new.cc, :new.nome, :new.telefone, :new.email, :new.data_nascimento);
    
    INSERT INTO Cliente 
    VALUES (:new.cc);
    
    INSERT INTO Premium 
    VALUES (:new.cc);
  END IF;
END;
/

CREATE OR REPLACE TRIGGER remove_premium
INSTEAD OF DELETE ON PremiumView
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :old.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    DELETE FROM Premium WHERE cc = :old.cc;
    DELETE FROM Cliente WHERE cc = :old.cc;
    DELETE FROM Pessoa WHERE cc = :old.cc;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER edita_premium
INSTEAD OF UPDATE ON PremiumView
FOR EACH ROW
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    UPDATE Pessoa
    SET cc = :new.cc, nome = :new.nome, telefone = :new.telefone, email = :new.email, data_nascimento = :new.data_nascimento
    WHERE cc = :old.cc;
    
    UPDATE Cliente
    SET cc = :new.cc
    WHERE cc = :old.cc;
    
    UPDATE Premium
    SET cc = :new.cc
    WHERE cc = :old.cc;
  END IF;
END;
/

                                                                       -- VIEW E TRIGGERS DO CLIENTE Basico --
                                                                       
CREATE OR REPLACE VIEW BasicView AS
SELECT cc, nome, telefone, email, data_nascimento, idGym
FROM Basico
INNER JOIN Cliente USING(cc)
INNER JOIN Pessoa USING(cc);   


CREATE OR REPLACE TRIGGER adiciona_basico
INSTEAD OF INSERT ON BasicView
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
  IF (Exist > 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Já existe uma pessoa com o mesmo id no sistema.');
  ELSE
    INSERT INTO Pessoa 
    VALUES (:new.cc, :new.nome, :new.telefone, :new.email, :new.data_nascimento);
    
    INSERT INTO Cliente 
    VALUES (:new.cc);
    
    INSERT INTO Basico
    VALUES (:new.cc, :new.idGym);
  END IF;
END;
/

CREATE OR REPLACE TRIGGER remove_basic
INSTEAD OF DELETE ON BasicView
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :old.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    DELETE FROM Basico WHERE cc = :old.cc;
    DELETE FROM Cliente WHERE cc = :old.cc;
    DELETE FROM Pessoa WHERE cc = :old.cc;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER edita_basic
INSTEAD OF UPDATE ON basicView
FOR EACH ROW
DECLARE
  Exist NUMBER;
BEGIN
  SELECT COUNT(*) INTO Exist FROM Pessoa WHERE cc = :new.cc;
  IF (Exist = 0) THEN
    RAISE_APPLICATION_ERROR (-20100, 'Não existe ninguém com o id inserido.');
  ELSE
    UPDATE Pessoa
    SET cc = :new.cc, nome = :new.nome, telefone = :new.telefone, email = :new.email, data_nascimento = :new.data_nascimento
    WHERE cc = :old.cc;
    
    UPDATE Cliente
    SET cc = :new.cc
    WHERE cc = :old.cc;
    
    UPDATE Basico
    SET cc = :new.cc, idGym = :new.idGym
    WHERE cc = :old.cc;
  END IF;
END;
/

                                                                    -- View para os Clientes --
                                                          
CREATE OR REPLACE VIEW ViewClientes AS
SELECT c.cc, p.nome, p.telefone, p.email, p.data_nascimento,
       CASE 
           WHEN pr.cc IS NOT NULL THEN 'Premium'
           WHEN ba.cc IS NOT NULL THEN 'Basico'
       END AS tipo
FROM Cliente c
LEFT JOIN Pessoa p ON c.cc = p.cc
LEFT JOIN Premium pr ON c.cc = pr.cc
LEFT JOIN Basico ba ON c.cc = ba.cc;   

CREATE OR REPLACE TRIGGER edita_cliente
INSTEAD OF UPDATE ON ViewClientes
FOR EACH ROW
DECLARE
  tipo_cliente VARCHAR(100);
BEGIN
  SELECT tipo INTO tipo_cliente FROM ViewClientes WHERE cc = :new.cc;
  
  IF (tipo_cliente = 'Basico') THEN
    UPDATE Basico
    SET cc = :new.cc
    WHERE cc = :old.cc;
  ELSIF (tipo_cliente = 'Premium') THEN
    UPDATE Premium
    SET cc = :new.cc
    WHERE cc = :old.cc;
  END IF;
  
  UPDATE Pessoa
  SET nome = :new.nome, telefone = :new.telefone, email = :new.email, data_nascimento = :new.data_nascimento
  WHERE cc = :new.cc;
END;
/

                                                              -- View para os Colaboradores --
                                                          
CREATE OR REPLACE VIEW ViewColaboradores AS
SELECT c.cc, p.nome, p.telefone, p.email, p.data_nascimento,
       CASE 
           WHEN pt.cc IS NOT NULL THEN 'PT'
           WHEN n.cc IS NOT NULL THEN 'Nutricionista'
           WHEN g.cc IS NOT NULL THEN 'Gerente'
       END AS tipo
FROM Colaborador c
LEFT JOIN Pessoa p ON c.cc = p.cc
LEFT JOIN PT pt ON c.cc = pt.cc
LEFT JOIN Nutricionista n ON c.cc = n.cc
LEFT JOIN Gerente g ON c.cc = g.cc;

CREATE OR REPLACE TRIGGER edita_colaborador
INSTEAD OF UPDATE ON ViewColaboradores
FOR EACH ROW
DECLARE
  tipo_colaborador VARCHAR(100);
BEGIN
  SELECT tipo INTO tipo_colaborador FROM ViewColaboradores WHERE cc = :new.cc;
  
  IF (tipo_colaborador = 'PT') THEN
    UPDATE PT
    SET cc = :new.cc
    WHERE cc = :old.cc;
  ELSIF (tipo_colaborador = 'Nutricionista') THEN
    UPDATE Nutricionista
    SET cc = :new.cc
    WHERE cc = :old.cc;
  ELSE
    UPDATE Gerente
    SET cc = :new.cc
    WHERE cc = :old.cc;
  END IF;
  
  UPDATE Pessoa
  SET nome = :new.nome, telefone = :new.telefone, email = :new.email, data_nascimento = :new.data_nascimento
  WHERE cc = :new.cc;
END;
/



                                                                       -- Serviço TREINO --
                                                                       
CREATE OR REPLACE VIEW TreinoView AS
SELECT idServico, data, hora, ccPT, ccPremium, tipo_treino
FROM Treino t
INNER JOIN Servico USING(idServico)
INNER JOIN PT p ON t.ccPT = p.cc
INNER JOIN Premium pr ON t.ccPremium = pr.cc;

-- TRIGGER adiciona_treino --
CREATE OR REPLACE TRIGGER adiciona_treino
INSTEAD OF INSERT ON TreinoView
DECLARE
  ExistPT NUMBER;
  ExistPremium NUMBER;
BEGIN
  SELECT COUNT(*) INTO ExistPT FROM PT WHERE cc = :new.ccPT;
  SELECT COUNT(*) INTO ExistPremium FROM Cliente WHERE cc = :new.ccPremium;
  
  IF (ExistPT = 0) THEN
    RAISE_APPLICATION_ERROR (-20101, 'O PT não existe.');
  ELSIF (ExistPremium = 0) THEN
    RAISE_APPLICATION_ERROR (-20102, 'O cliente premium não existe.');
  ELSE
    INSERT INTO Servico 
    VALUES (:new.idServico, :new.data, :new.hora);
    
    INSERT INTO Treino 
    VALUES (:new.idServico, :new.ccPT, :new.ccPremium, :new.tipo_treino);
  END IF;
END;
/


-- TRIGGER remove_treino --
CREATE OR REPLACE TRIGGER remove_treino
INSTEAD OF DELETE ON TreinoView
DECLARE
  ExistServico NUMBER;
BEGIN
  SELECT COUNT(*) INTO ExistServico FROM Servico WHERE idServico = :old.idServico;
  
  IF (ExistServico = 0) THEN
    RAISE_APPLICATION_ERROR (-20103, 'O treino não existe.');
  ELSE
    DELETE FROM Treino WHERE idServico = :old.idServico;
    DELETE FROM Servico WHERE idServico = :old.idServico;
  END IF;
END;
/


-- TRIGGER edita_treino --
CREATE OR REPLACE TRIGGER edita_treino
INSTEAD OF UPDATE ON TreinoView
FOR EACH ROW
DECLARE
  ExistPT NUMBER;
  ExistPremium NUMBER;
BEGIN
  SELECT COUNT(*) INTO ExistPT FROM PT WHERE cc = :new.ccPT;
  SELECT COUNT(*) INTO ExistPremium FROM Cliente WHERE cc = :new.ccPremium;
  
  IF (ExistPT = 0) THEN
    RAISE_APPLICATION_ERROR (-20101, 'O PT não existe.');
  ELSIF (ExistPremium = 0) THEN
    RAISE_APPLICATION_ERROR (-20102, 'O cliente premium não existe.');
  ELSE
    UPDATE Servico
    SET idServico = :new.idServico, data = :new.data, hora = :new.hora
    WHERE idServico = :old.idServico;
    
    UPDATE Treino
    SET idServico = :new.idServico, ccPT = :new.ccPT, ccPremium = :new.ccPremium, tipo_treino = :new.tipo_treino
    WHERE idServico = :old.idServico;
  END IF;
END;
/

                                                                       -- Serviço Consulta --
                                                                       
CREATE OR REPLACE VIEW ConsultaView AS
SELECT idServico, data, hora, ccNutricionista, ccCliente, objetivo
FROM Consulta c
INNER JOIN Servico USING(idServico)
INNER JOIN Nutricionista n ON c.ccNutricionista = n.cc
INNER JOIN Cliente cliente ON c.ccCliente = cliente.cc;

-- TRIGGER adiciona_consulta --
CREATE OR REPLACE TRIGGER adiciona_consulta
INSTEAD OF INSERT ON ConsultaView
DECLARE
  ExistNutri NUMBER;
  ExistCliente NUMBER;
BEGIN
  SELECT COUNT(*) INTO ExistNutri FROM Nutricionista WHERE cc = :new.ccNutricionista;
  SELECT COUNT(*) INTO ExistCliente FROM Cliente WHERE cc = :new.ccCliente;
  
  IF (ExistNutri = 0) THEN
    RAISE_APPLICATION_ERROR (-20101, 'O Nutricionista não existe.');
  ELSIF (ExistCliente = 0) THEN
    RAISE_APPLICATION_ERROR (-20102, 'O cliente não existe.');
  ELSE
    INSERT INTO Servico 
    VALUES (:new.idServico, :new.data, :new.hora);
    
    INSERT INTO Consulta
    VALUES (:new.idServico, :new.ccNutricionista, :new.ccCliente, :new.objetivo);
  END IF;
END;
/


-- TRIGGER remove_consulta --
CREATE OR REPLACE TRIGGER remove_consulta
INSTEAD OF DELETE ON ConsultaView
DECLARE
  ExistServico NUMBER;
BEGIN
  SELECT COUNT(*) INTO ExistServico FROM Servico WHERE idServico = :old.idServico;
  
  IF (ExistServico = 0) THEN
    RAISE_APPLICATION_ERROR (-20106, 'A consulta não existe.');
  ELSE
    DELETE FROM Consulta WHERE idServico = :old.idServico;
    DELETE FROM Servico WHERE idServico = :old.idServico;
  END IF;
END;
/

-- TRIGGER edita_consulta --
CREATE OR REPLACE TRIGGER edita_consulta
INSTEAD OF UPDATE ON ConsultaView
FOR EACH ROW
DECLARE
  ExistNutri NUMBER;
  ExistCliente NUMBER;
BEGIN
  SELECT COUNT(*) INTO ExistNutri FROM Nutricionista WHERE cc = :new.ccNutricionista;
  SELECT COUNT(*) INTO ExistCliente FROM Cliente WHERE cc = :new.ccCliente;
  
  IF (ExistNutri = 0) THEN
    RAISE_APPLICATION_ERROR (-20104, 'O nutricionista não existe.');
  ELSIF (ExistCliente = 0) THEN
    RAISE_APPLICATION_ERROR (-20105, 'O cliente não existe.');
  ELSE
    UPDATE Servico
    SET idServico = :new.idServico, data = :new.data, hora = :new.hora
    WHERE idServico = :old.idServico;
    
    UPDATE Consulta
    SET idServico = :new.idServico, ccNutricionista = :new.ccNutricionista, ccCliente = :new.ccCliente, objetivo = :new.objetivo
    WHERE idServico = :old.idServico;
  END IF;
END;
/


                                                                     -- VIEW PARA OS GERENTES --
CREATE OR REPLACE VIEW GerenteView AS
SELECT cc, nome, telefone, email, data_nascimento
FROM Gerente
INNER JOIN Colaborador USING(cc)
INNER JOIN Pessoa USING(cc);




-- CONSULTAS INTERESSANTES
  
   -- OBTER O NUTRICIONISTA COM MAIS CONSULTAS ATÉ AO MOMENTO
CREATE OR REPLACE VIEW NutriMaisConsultasView AS
SELECT ccNutricionista, COUNT(*) AS total_consultas
FROM Consulta
GROUP BY ccNutricionista
ORDER BY total_consultas DESC
FETCH FIRST ROW ONLY;

    -- Obter as pessoas que têm treinos com um determinado PT
CREATE OR REPLACE VIEW TreinosComUmPt AS
SELECT pe.*,pt.cc AS ccPT
FROM PT pt
LEFT JOIN Treino t ON(t.ccPT= pt.cc)
LEFT JOIN Premium p ON (t.ccPremium = p.cc)
LEFT JOIN Pessoa pe ON (p.cc = pe.cc);

   -- TODOS OS MEMBROS QUE JÁ TIVERAM PELO MENOS 3 CONSULTAS COM O MESMO NUTRICIONISTA
CREATE OR REPLACE VIEW MembrosMais3Consultas AS
SELECT c.ccCliente, c.ccNutricionista, COUNT(*) AS total_consultas
FROM Consulta c
WHERE c.ccCliente IN (
    SELECT ccCliente
    FROM Consulta
    GROUP BY ccCliente, ccNutricionista
    HAVING COUNT(*) >= 3
)
GROUP BY c.ccCliente, c.ccNutricionista;


   -- TODOS OS MEMBROS QUE JÁ TIVERAM PELO MENOS 2 CONSULTAS E 2 TREINOS
CREATE OR REPLACE VIEW MembroDuasConsultasTreinos AS
SELECT p.cc, p.email, COUNT(DISTINCT t.idServico) AS num_treinos, COUNT(DISTINCT co.idServico) AS num_consultas
FROM Cliente c
JOIN Premium pr ON c.cc = pr.cc
JOIN Treino t ON c.cc = t.ccPremium
JOIN Consulta co ON c.cc = co.ccCliente
JOIN Pessoa p ON p.cc = c.cc
GROUP BY p.cc, p.email
HAVING COUNT(DISTINCT t.idServico) >= 2 AND COUNT(DISTINCT co.idServico) >= 2;



                                                   
                -- INSERTS --
    
-- Inserts para Gerentes

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (1001, 'Ana Santos', 987654321, 'ana.santos@fitnation.com', TO_DATE('01-01-1990', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (1001);
INSERT INTO Gerente (cc) VALUES (1001);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (1002, 'Pedro Silva', 915854322, 'pedro.silva@fitnation.com', TO_DATE('02-02-1981', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (1002);
INSERT INTO Gerente (cc) VALUES (1002);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (1003, 'Marta Costa', 960154323, 'marta.costa@fitnation.com', TO_DATE('03-03-1999', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (1003);
INSERT INTO Gerente (cc) VALUES (1003);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (1004, 'Nuno Preguiça', 927594371, 'npreguica@fitnation.com', TO_DATE('01-07-1996', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (1004);
INSERT INTO Gerente (cc) VALUES (1004);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (1005, 'André Lamúrias', 927594371, 'andré.lamúrias@fitnation.com', TO_DATE('31-07-1996', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (1005);
INSERT INTO Gerente (cc) VALUES (1005);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (1006, 'Nuno Preguiça', 927594371, 'npreguica@fitnation.com', TO_DATE('31-07-1976', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (1006);
INSERT INTO Gerente (cc) VALUES (1006);


--------------------------------------------------------------------------------


-- Inserts para Gyms
-- Inserir ginásio com ID 1
INSERT INTO Gym (idGym, telemovel, cidade, rua, cc)
VALUES (1, 987654321, 'Lisboa', 'Avenida da Liberdade', 1001);

-- Inserir ginásio com ID 2
INSERT INTO Gym (idGym, telemovel, cidade, rua, cc)
VALUES (2, 987654322, 'Porto', 'Rua de Santa Catarina', 1002);

-- Inserir ginásio com ID 3
INSERT INTO Gym (idGym, telemovel, cidade, rua, cc)
VALUES (3, 987654323, 'Coimbra', 'Rua da Sofia', 1003);

-- Inserir ginásio com ID 4
INSERT INTO Gym (idGym, telemovel, cidade, rua, cc)
VALUES (4, 987654324, 'Faro', 'Rua Conselheiro Bivar', 1004);

-- Inserir ginásio com ID 5
INSERT INTO Gym (idGym, telemovel, cidade, rua, cc)
VALUES (5, 987654325, 'Braga', 'Avenida Central', 1005);

-- Inserir ginásio com ID 6
INSERT INTO Gym (idGym, telemovel, cidade, rua, cc)
VALUES (6, 987654326, 'Aveiro', 'Rua João Mendonça', 1006);


---------------------------------------------------------------------------------

-- Inserts para Clientes básicos
-- Inserir pessoa com CC 2001
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2001, 'João Santos', 911234567, 'joao.santos@gmail.com', TO_DATE('01-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2001);
INSERT INTO Basico (cc, idGym) VALUES (2001, 1);

-- Inserir pessoa com CC 2002
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2002, 'Maria Silva', 939876543, 'maria.silva@gmail.com', TO_DATE('02-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2002);
INSERT INTO Basico (cc, idGym) VALUES (2002, 1);

-- Inserir pessoa com CC 2003
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2003, 'Manuel Costa', 920987654, 'manuel.costa@outlook.com', TO_DATE('03-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2003);
INSERT INTO Basico (cc, idGym) VALUES (2003, 2);

-- Inserir pessoa com CC 2004
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2004, 'Sofia Martins', 913456789, 'sofia.martins@gmail.com', TO_DATE('04-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2004);
INSERT INTO Basico (cc, idGym) VALUES (2004, 2);

-- Inserir pessoa com CC 2005
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2005, 'António Pereira', 939765432, 'antonio.pereira@outlook.com', TO_DATE('05-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2005);
INSERT INTO Basico (cc, idGym) VALUES (2005, 3);

-- Inserir pessoa com CC 2006
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2006, 'Inês Gonçalves', 920876543, 'ines.goncalves@gmail.com', TO_DATE('06-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2006);
INSERT INTO Basico (cc, idGym) VALUES (2006, 4);

-- Inserir pessoa com CC 2007
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2007, 'Rui Fernandes', 913567890, 'rui.fernandes@outlook.com', TO_DATE('07-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2007);
INSERT INTO Basico (cc, idGym) VALUES (2007, 3);

-- Inserir pessoa com CC 2008 no ginásio 3
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2008, 'Miguel Almeida', 912345678, 'miguel.almeida@gmail.com', TO_DATE('08-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2008);
INSERT INTO Basico (cc, idGym) VALUES (2008, 3);

-- Inserir pessoa com CC 2009 no ginásio 3
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2009, 'Carolina Santos', 913456789, 'carolina.santos@outlook.com', TO_DATE('09-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2009);
INSERT INTO Basico (cc, idGym) VALUES (2009, 3);

-- Inserir pessoa com CC 2010 no ginásio 3
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2010, 'Diogo Costa', 914567890, 'diogo.costa@gmail.com', TO_DATE('10-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2010);
INSERT INTO Basico (cc, idGym) VALUES (2010, 3);

-- Inserir pessoa com CC 2011 no ginásio 5
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2011, 'Beatriz Fernandes', 920987654, 'beatriz.fernandes@gmail.com', TO_DATE('11-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2011);
INSERT INTO Basico (cc, idGym) VALUES (2011, 5);

-- Inserir pessoa com CC 2012 no ginásio 5
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2012, 'Gonçalo Silva', 921098765, 'goncalo.silva@outlook.com', TO_DATE('12-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2012);
INSERT INTO Basico (cc, idGym) VALUES (2012, 5);

-- Inserir pessoa com CC 2013 no ginásio 5
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2013, 'Lara Pereira', 922109876, 'lara.pereira@gmail.com', TO_DATE('13-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2013);
INSERT INTO Basico (cc, idGym) VALUES (2013, 5);

-- Inserir pessoa com CC 2014 no ginásio 4
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2014, 'Tiago Martins', 930000000, 'tiago.martins@gmail.com', TO_DATE('14-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2014);
INSERT INTO Basico (cc, idGym) VALUES (2014, 4);

-- Inserir pessoa com CC 2015 no ginásio 4
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2015, 'Mariana Sousa', 931111111, 'mariana.sousa@outlook.com', TO_DATE('15-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2015);
INSERT INTO Basico (cc, idGym) VALUES (2015, 4);

-- Inserir pessoa com CC 2016 no ginásio 4
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2016, 'Ricardo Carvalho', 932222222, 'ricardo.carvalho@gmail.com', TO_DATE('16-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2016);
INSERT INTO Basico (cc, idGym) VALUES (2016, 4);

-- Inserir pessoa com CC 2017 no ginásio 5
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2017, 'Miguel Fernandes', 931234567, 'miguel.fernandes@gmail.com', TO_DATE('17-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2017);
INSERT INTO Basico (cc, idGym) VALUES (2017, 5);

-- Inserir pessoa com CC 2018 no ginásio 5
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2018, 'Ana Costa', 933456789, 'ana.costa@outlook.com', TO_DATE('18-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2018);
INSERT INTO Basico (cc, idGym) VALUES (2018, 5);

-- Inserir pessoa com CC 2019 no ginásio 6
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2019, 'Rui Oliveira', 941234567, 'rui.oliveira@gmail.com', TO_DATE('19-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2019);
INSERT INTO Basico (cc, idGym) VALUES (2019, 6);

-- Inserir pessoa com CC 2020 no ginásio 6
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2020, 'Mariana Carvalho', 943456789, 'mariana.carvalho@outlook.com', TO_DATE('20-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2020);
INSERT INTO Basico (cc, idGym) VALUES (2020, 6);

-- Inserir pessoa com CC 2021 no ginásio 6
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2021, 'José Sousa', 945678901, 'jose.sousa@gmail.com', TO_DATE('21-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2021);
INSERT INTO Basico (cc, idGym) VALUES (2021, 6);

-- Inserir pessoa com CC 2022 no ginásio 6
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2022, 'Inês Almeida', 947890123, 'ines.almeida@gmail.com', TO_DATE('22-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2022);
INSERT INTO Basico (cc, idGym) VALUES (2022, 6);

-- Inserir pessoa com CC 2023 no ginásio 3
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2023, 'Luís Martins', 951234567, 'luis.martins@gmail.com', TO_DATE('23-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2023);
INSERT INTO Basico (cc, idGym) VALUES (2023, 3);

-- Inserir pessoa com CC 2024 no ginásio 3
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2024, 'Sara Costa', 953456789, 'sara.costa@outlook.com', TO_DATE('24-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2024);
INSERT INTO Basico (cc, idGym) VALUES (2024, 3);

-- Inserir pessoa com CC 2025 no ginásio 3
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2025, 'André Silva', 955678901, 'andre.silva@gmail.com', TO_DATE('25-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2025);
INSERT INTO Basico (cc, idGym) VALUES (2025, 3);

-- Inserir pessoa com CC 2026 no ginásio 1
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2026, 'Marta Rodrigues', 910123456, 'marta.rodrigues@gmail.com', TO_DATE('26-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2026);
INSERT INTO Basico (cc, idGym) VALUES (2026, 1);

-- Inserir pessoa com CC 2027 no ginásio 1
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2027, 'Bruno Santos', 912345678, 'bruno.santos@outlook.com', TO_DATE('27-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2027);
INSERT INTO Basico (cc, idGym) VALUES (2027, 1);

-- Inserir pessoa com CC 2028 no ginásio 4
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2028, 'Joana Pereira', 920123456, 'joana.pereira@gmail.com', TO_DATE('28-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2028);
INSERT INTO Basico (cc, idGym) VALUES (2028, 4);

-- Inserir pessoa com CC 2029 no ginásio 4
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2029, 'Hugo Ferreira', 922345678, 'hugo.ferreira@outlook.com', TO_DATE('29-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2029);
INSERT INTO Basico (cc, idGym) VALUES (2029, 4);

-- Inserir pessoa com CC 2030 no ginásio 4
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2030, 'Carolina Gomes', 924567890, 'carolina.gomes@gmail.com', TO_DATE('30-01-1990', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2030);
INSERT INTO Basico (cc, idGym) VALUES (2030, 4);
---------------------------------------------------------------------------------

-- Inserts para Clientes premium
-- Inserir pessoa com CC 2031 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2031, 'Rui Pereira', 928765348, 'rpereira87@gmail.com', TO_DATE('02-03-1987', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2031);
INSERT INTO Premium (cc) VALUES (2031);


-- Inserir pessoa com CC 2032 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2032, 'Pedro Santos', 913456789, 'pedro.santos@gmail.com', TO_DATE('02-03-1987', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2032);
INSERT INTO Premium (cc) VALUES (2032);

-- Inserir pessoa com CC 2033 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2033, 'Sofia Costa', 915678901, 'sofia.costa@gmail.com', TO_DATE('03-05-1989', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2033);
INSERT INTO Premium (cc) VALUES (2033);

-- Inserir pessoa com CC 2034 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2034, 'Rui Rodrigues', 917890123, 'rui.rodrigues@gmail.com', TO_DATE('04-07-1991', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2034);
INSERT INTO Premium (cc) VALUES (2034);

-- Inserir pessoa com CC 2035 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2035, 'Inês Alves', 919012345, 'ines.alves@gmail.com', TO_DATE('05-09-1993', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2035);
INSERT INTO Premium (cc) VALUES (2035);

-- Inserir pessoa com CC 2036 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2036, 'Tiago Ferreira', 921234567, 'tiago.ferreira@gmail.com', TO_DATE('06-11-1995', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2036);
INSERT INTO Premium (cc) VALUES (2036);

-- Inserir pessoa com CC 2037 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2037, 'Mariana Costa', 923456789, 'mariana.costa@gmail.com', TO_DATE('07-01-1998', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2037);
INSERT INTO Premium (cc) VALUES (2037);

-- Inserir pessoa com CC 2038 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2038, 'Carlos Silva', 925678901, 'carlos.silva@gmail.com', TO_DATE('08-03-2000', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2038);
INSERT INTO Premium (cc) VALUES (2038);

-- Inserir pessoa com CC 2039 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2039, 'Ana Santos', 927890123, 'ana.santos@gmail.com', TO_DATE('09-05-2002', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2039);
INSERT INTO Premium (cc) VALUES (2039);

-- Inserir pessoa com CC 2040 como Cliente Premium
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2040, 'Hugo Rodrigues', 929012345, 'hugo.rodrigues@gmail.com', TO_DATE('10-06-2004', 'dd-mm-yyyy'));
INSERT INTO Cliente (cc) VALUES (2040);
INSERT INTO Premium (cc) VALUES (2040);


----------------------------------------------------------------------------------


-- Inserts para PTs
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (182736128376, 'Máximo Volynets', 960019801, 'm.volynets@fitnation.com', TO_DATE('01-10-1999', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (182736128376);
INSERT INTO PT (cc, certificado) VALUES (182736128376, 189302);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (304958039485, 'Pedro Gonçalves', 960895854, 'p.goncalves@fitnation.com', TO_DATE('31-07-2002', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (304958039485);
INSERT INTO PT (cc, certificado) VALUES (304958039485, 189450);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (230948203948, 'Catarina Pinto', 929857801, 'cpinto99@fitnation.com', TO_DATE('26-07-1999', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (230948203948);
INSERT INTO PT (cc, certificado) VALUES (230948203948, 178256);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (12039810293, 'José Boteho', 910989413, 'j.Bote@fitnation.com', TO_DATE('14-05-2001', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (12039810293);
INSERT INTO PT (cc, certificado) VALUES (12039810293, 197367);

INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (120938102983, 'Carlos Silva', 967463581, 'csilva@fitnation.com', TO_DATE('31-12-1989', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (120938102983);
INSERT INTO PT (cc, certificado) VALUES (120938102983, 163748);


--------------------------------------------------------------------------------

-- Inserts para Nutricionistas
INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (1738543, 'Dinis Volynets', 912873756, 'dinisvolynets@fitnation.com', TO_DATE('18-12-2001', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (1738543);
INSERT INTO Nutricionista (cc, ordem) VALUES (1738543, 54853);


INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (184637, 'João Marques', 912847465, 'nutricionista1@fitnation.com', TO_DATE('14-01-2002', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (184637);
INSERT INTO Nutricionista (cc, ordem) VALUES (184637, 18264);


INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (284659, 'Mariana Teotónio', 938738645, 'm.teotonio@fitnation.com', TO_DATE('02-07-1995', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (284659);
INSERT INTO Nutricionista (cc, ordem) VALUES (284659, 19836);


INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (2937495, 'Pedro Santos', 964375865, 'p.santos@fitnation.com', TO_DATE('07-09-1997', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (2937495);
INSERT INTO Nutricionista (cc, ordem) VALUES (2937495, 64833);


INSERT INTO Pessoa (cc, nome, telefone, email, data_nascimento)
VALUES (29387593, 'Valdo António', 91273849, 'v.antonio@fitnation.com', TO_DATE('22-10-1998', 'dd-mm-yyyy'));
INSERT INTO Colaborador (cc) VALUES (29387593);
INSERT INTO Nutricionista (cc, ordem) VALUES (29387593, 84630);


                                          
