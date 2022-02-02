-- Part II - Create the DDL for your new schema

-- Guideline #1: here is a list of features and specifications that Udiddit needs in order to support its website and administrative interface:

-- a. Allow new users to register
-- i. Each username has to be unique
-- ii. Usernames can be composed of at most 25 characters

CREATE TABLE "usuarios" (
  "usuario_id" SERIAL PRIMARY KEY,
  "nome_de_usuario" VARCHAR(25) CONSTRAINT "usuario_unico" UNIQUE
);

-- iii. Usernames can’t be empty

ALTER TABLE "usuarios" ADD CONSTRAINT "usuario_nao_nulo" CHECK (LENGTH(nome_de_usuario) > 0);

-- b. Allow registered users to create new topics ->  a tabela deve ter, pelo menos, o tópico e o usuário
-- i. Topic names have to be unique
-- ii. The topic’s name is at most 30 characters
-- iv. Topics can have an optional description of at most 500 characters

CREATE TABLE "topicos" (
  "topico_id" SERIAL PRIMARY KEY,
  "nome_do_topico" VARCHAR(30) CONSTRAINT "nome_do_topico_unico" UNIQUE,
  "descricao" VARCHAR(500),
  "usuario_id" INTEGER CONSTRAINT "usuario_valido" REFERENCES "usuarios"("usuario_id") ON DELETE SET NULL 
);

-- iii. The topic’s name can’t be empty

ALTER TABLE "topicos" ADD CONSTRAINT "topico_nao_nulo" CHECK (LENGTH(nome_do_topico) > 0);

-- c. Allow registered users to create new posts on existing topics -> a tabela deve ter, pelo menos, o post, o tópico e o usuário
-- i. Posts have a required title of at most 100 characters
-- iv. If a topic gets deleted, all the posts associated with it should be automatically deleted too
-- v. If the user who created the post gets deleted, then the post will remain, but it will become dissociated from that user

CREATE TABLE "posts" (
  "post_id" SERIAL PRIMARY KEY,
  "titulo_do_post" VARCHAR(100),
  "url" TEXT,
  "conteudo" TEXT
  "topico_id" INTEGER CONSTRAINT "topico_valido" REFERENCES "topicos"("topico_id") ON DELETE CASCADE,
  "usuario_id" INTEGER CONSTRAINT "usuario_valido" REFERENCES "usuarios"("usuario_id") ON DELETE SET NULL
);

-- ii. The title of a post can’t be empty

ALTER TABLE "posts" ADD CONSTRAINT "titulo_nao_nulo" CHECK (LENGTH(titulo_do_post) > 0);

-- iii. Posts should contain either a URL or a text content, but not both.

ALTER TABLE "posts" ADD CONSTRAINT "url_ou_conteudo" CHECK (("url" IS NULL AND "conteudo" IS NOT NULL) OR ("url" IS NOT NULL AND "conteudo" IS NULL));

-- d. Allow registered users to comment on existing posts -> a tabela deve ter, pelo menos, o comentário, o post e o usuário
-- iii. If a post gets deleted, all comments associated with it should be automatically deleted too
-- iv. If the user who created the comment gets deleted, then the comment will remain, but it will become dissociated from that user

CREATE TABLE "comentarios" (
  "comentario_id" SERIAL PRIMARY KEY,
  "comentario" TEXT,
  "post_id" INTEGER CONSTRAINT "post_valido" REFERENCES "posts"("post_id") ON DELETE CASCADE,
  "usuario_id" INTEGER CONSTRAINT "usuario_valido" REFERENCES "usuarios"("usuario_id") ON DELETE SET NULL
);

-- i. A comment’s text content can’t be empty
ALTER TABLE "comentarios" ADD CONSTRAINT "comentario_nao_nulo" CHECK (LENGTH(comentario) > 0);

-- ii. Contrary to the current linear comments, the new structure should allow comment threads at arbitrary levels
-- v. If a comment gets deleted, then all its descendants in the thread structure should be automatically deleted too

ALTER TABLE "comentarios" ADD COLUMN "nivel_do_comentario" INTEGER CHECK ("nivel_do_comentario" >= 1);

-- o comentário, seja ele o pai, seja ele o descendente, não deixa de ser somente um comentário e, por isso, eu decidi por adicionar somente um nível a ele e posteriormente 
-- o website separa e mostra esses comentários de acordo com seu nível. Porque, a final de contas, ele continua sendo somente mais um comentário

-- a minha ideia aqui é que o primeiro comentário tenha o nível 1, as respostas a esse comentário tenham o nível 2 e assim sucessivamente

-- e. Make sure that a given user can only vote once on a given post -> a tabela deve ter, pelo menos, o usuário, o voto e o post
-- i. If the user who cast a vote gets deleted, then all their votes will remain, but will become dissociated from the user
-- ii. If a post gets deleted, then all the votes for that post should be automatically deleted too

CREATE TABLE "votos" (
  "usuario_id" INTEGER CONSTRAINT "usuario_valido" REFERENCES "usuarios"("usuario_id") ON DELETE SET NULL,
  "post_id" INTEGER CONSTRAINT "post_valido" REFERENCES "posts"("post_id") ON DELETE CASCADE,
  "voto" SMALLINT,
  CONSTRAINT "id" PRIMARY KEY ("usuario_id", "post_id"),
  CONSTRAINT "voto_unico_por_usuario" UNIQUE ("post_id", "usuario_id")
);

ALTER TABLE "votos" ADD CONSTRAINT "voto_valido" CHECK ("voto" = '-1' OR "voto" = '1'); -- os votos positivos serão lidos como 1 e os negativos como -1

-- 2. Guideline #2: here is a list of queries that Udiddit needs in order to support its website and administrative interface. Note that you don’t need to produce the 
-- DQL for those queries: they are only provided to guide the design of your new database schema.

-- a. List all users who haven’t logged in in the last year.

CREATE TABLE "log_in" (
  "usuario_id" INTEGER CONSTRAINT "usuario_valido"
    REFERENCES "usuarios"("usuario_id"),
  "quando" TIMESTAMP WITH TIME ZONE -- uma rede social, normalmente, tem escala global e, por isso, decidi manter os fuso-horários
);

-- b. List all users who haven’t created any post

-- Já é possível ter essa resposta ao usar, por exemplo, a função SELECT u.usuario_id FROM posts AS p RIGHT JOIN usuarios AS u WHERE u.usuario_id IS NOT IN posts

-- c. Find a user by their username

-- Já é possível fazer isso, pois o nome de usuário é único, mas podemos facilitar essa busca ao criar um index

CREATE INDEX "achar_usuario" ON "usuarios"("nome_de_usuario");

-- d. List all topics that don’t have any posts

-- Assim como na letra b, já é possível fazer isso por meio de DQLs

-- e. Find a topic by its name

-- Assim como na letra c, já é possível fazer isso, pois o nome do tópico é único, mas podemos facilitar essa busca ao criar um index

CREATE INDEX "achar_topico" ON "topicos"("nome_do_topico");

-- f. List the latest 20 posts for a given topic
-- g. List the latest 20 posts made by a given user

ALTER TABLE "posts" ADD COLUMN "quando" TIMESTAMP WITH TIME ZONE;

-- h. List all the top-level comments (those that don’t have a parent comment) for a given post
-- i. List all the direct children of a parent comment

-- Assim como em questões anteriores, já é possível fazer isso com, por exemplo, SELECT * FROM comentarios WHERE nivel_do_comentario = 1 (no caso de comentários pais), mas é possível
-- criar um index para facilitar essa busca

CREATE INDEX "comentario_original" ON "comentarios"("nivel_do_comentario");

-- j. List the latest 20 comments made by a given user

ALTER TABLE "comentarios" ADD COLUMN "quando" TIMESTAMP WITH TIME ZONE;

-- l. Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes

-- Já é possível fazer isso por meio de DQLs. Como, por exemplo, SELECT SUM(voto) FROM votos WHERE post_id = 123, mas, novamente, pode-se criar um index para facilitar a busca pelo 
-- post

CREATE INDEX "achar_post" ON "votos"("post_id");

-- Part III - Migrate the provided data

-- Primeiro, vou migrar os dados referentes ao usuário, pois sem eles não é possível interagir com nada da rede social, e vou fazendo as migrações como se fosse uma árvore e suas
-- ramificações 

-- Pegarei todos os nomes de usuários e os jogarei em uma tabela provisória. Nessa tabela, usarei o comando SELECT DISTINCT para selecionar os usuários sem repeti-los e então os
-- armazenarei na tabela final "usuarios"

CREATE TABLE "usuarios_tabela_provisoria" (
  "id" SERIAL PRIMARY KEY,
  "usuario" VARCHAR(25)
);

INSERT INTO "usuarios_tabela_provisoria"("usuario") (
  SELECT username
    FROM bad_comments
  );

INSERT INTO "usuarios_tabela_provisoria"("usuario") (
  SELECT username
    FROM bad_posts
);

INSERT INTO "usuarios_tabela_provisoria"("usuario") (
  SELECT regexp_split_to_table("upvotes", ',')
    FROM bad_posts
);

INSERT INTO "usuarios_tabela_provisoria"("usuario") (
  SELECT regexp_split_to_table("downvotes", ',')
    FROM bad_posts
);

INSERT INTO "usuarios"("nome_de_usuario") (
  SELECT DISTINCT usuario
    FROM usuarios_tabela_provisoria
);

DROP TABLE "usuarios_tabela_provisoria";

-- Tópicos

-- 1.Topic descriptions can all be empty

INSERT INTO "topicos"("nome_do_topico", "descricao")
  SELECT DISTINCT topic,
                  NULL AS descricao
             FROM bad_posts;

-- Posts

-- Durante a avaliação do trabalho, esse foi um código que gerou muitos questionamentos por parte dos avaliadores. Então vou explicar meu raciocínio aqui. Durante a criação do banco 
-- de dados, foi pedido que os títulos dos posts tivessem no máximo 100 caracteres. No entanto, no antigo banco de dados já haviam títulos cujo número de caracteres extrapolava esse 
-- limite. Dessa forma, pensei dividir a migração dos posts em duas partes. Na primeira, migraria os posts cujos títulos tinham mais de 100 espaços e faria isso selecionando seus 
-- primeiros 97 caracteres e adicionando reticências ao final. Na segunda parte, migraria normalmente os posts cujos títulos já obedeciam ao limite criado.

-- Repare que decidi por migrar também a coluna "post_id" ao invés de deixar que meu banco de dados os criasse automaticamente e futuramente veremos o porquê.

INSERT INTO "posts"("post_id", "titulo_do_post", "url", "conteudo", "topico_id", "usuario_id")
  SELECT bp.id,
         CONCAT(LEFT(bp.title, 97), '...'),
         bp.text_content,
         t.topico_id AS topico_id,
         u.usuario_id AS usuario_id
    FROM bad_posts AS bp
    JOIN topicos AS t
      ON bp.topic = t.nome_do_topico
    JOIN usuarios AS u
      ON bp.username = u.nome_de_usuario
   WHERE LENGTH(bp.title) > 100;

INSERT INTO "posts"("post_id", "titulo_do_post", "url", "conteudo", "topico_id", "usuario_id")
  SELECT bp.id,
         bp.title,
         bp.url,
         bp.text_content,
         t.topico_id AS topico_id,
         u.usuario_id AS usuario_id
    FROM bad_posts AS bp
    JOIN topicos AS t
      ON bp.topic = t.nome_do_topico
    JOIN usuarios AS u
      ON bp.username = u.nome_de_usuario
   WHERE LENGTH(bp.title) <= 100;

-- Comentarios

-- 2. Since the bad_comments table doesn’t have the threading feature, you can migrate all comments as top-level comments, i.e. without a parent

INSERT INTO "comentarios"("comentario", "post_id", "usuario_id", "nivel_do_comentario")
  SELECT bc.text_content,
         bc.post_id,
         u.usuario_id,
         '1'
    FROM bad_comments AS bc
    JOIN usuarios AS u
      ON bc.username = u.nome_de_usuario;

-- Votos

-- Para que eu conseguisse relacionar os usuarios aos posts, usei a coluna "post_id" contido na tabela "bad_posts", e foi por isso que a mantive durante a migração

INSERT INTO "votos"("usuario_id", "post_id", "voto")
  SELECT u.usuario_id,
         vp.post_id,
         '1'
    FROM (SELECT id AS post_id,
                 regexp_split_to_table("upvotes", ',') AS usuario
            FROM bad_posts) AS vp
    JOIN usuarios AS u
      ON vp.usuario = u.nome_de_usuario;

INSERT INTO "votos"("usuario_id", "post_id", "voto")
  SELECT u.usuario_id,
         vn.post_id,
         '-1'
    FROM (SELECT id AS post_id,
                 regexp_split_to_table("downvotes", ',') AS usuario
            FROM bad_posts) AS vn
    JOIN usuarios AS u
      ON vn.usuario = u.nome_de_usuario;
