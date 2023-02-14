#!/usr/bin/perl -i

print "Content-type: text/html\n\n";

# Получаем данные
#####################################
if ($ENV{'REQUEST_METHOD'} eq "POST") {
    read(STDIN, $bufer, $ENV{'CONTENT_LENGTH'});
} elsif ($ENV{'REQUEST_METHOD'} eq "GET") {
    $bufer=$ENV{'QUERY_STRING'};
} else {}
@pairs = split(/&/, $bufer);
foreach $pair (@pairs){
    ($name, $value) = split(/=/, $pair);
    $name =~ tr/+/ /;
    $name =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
    $value =~ tr/+/ /;
    $value =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
    $FORM{$name} = $value;
}

$email=ADDSLASEH($FORM{'email'});

# Функция экранирования
#####################################
sub ADDSLASEH() {
    my ($this) = @_;
    $this =~ s/([\"\'\`\\])/\\$1/sg;
    return $this;
}

# Подключаем модули
#####################################
use DBI;						        # Модуль для работы с базой данных

# Сервер MySQL
#####################################
our $host_db        = "localhost";		# ip MySQL-сервера
our $port_db        = "3306";			# порт, на который открываем соединение
our $user_db        = "gremlin";		# имя пользователя
our $password_db    = "gremlin5";  		# пароль
our $db             = "test_serv"; 		# имя базы данных
#####################################

# Проверка доступности базы
#####################################
my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host_db;port=$port_db","$user_db","$password_db",{PrintError => 0, RaiseError => 0, AutoCommit => 0});
if (!$dbh){
    print "Error DB base...";
    $dbh->disconnect;
    exit;
}

# Проверяем на валидность email
if (($email) && ($email =~ /^[a-z0-9]([a-z0-9.]+[a-z0-9])?\@[a-z0-9.-]+$/)) {

# Всего записей
$all_line = $dbh->prepare("SELECT count(l.`int_id`) FROM `log` l LEFT JOIN `message` m ON(l.`int_id` = m.`int_id`) WHERE l.`address` = '$email'");
$all_line->execute;
$all = $all_line->fetchrow_array();
$all_line->finish;

##### Запрашиваем данные
my $check_data = $dbh->prepare("SELECT m.`created`,m.`str`,l.`created`,l.`str`,l.`address` 
FROM `log` l 
LEFT JOIN `message` m ON(l.`int_id` = m.`int_id`) 
WHERE l.`address` = '$email' 
ORDER BY l.`created` DESC, m.`created` DESC, m.`int_id` DESC LIMIT 100");
$check_data->execute;

while( my ($created_l,$str_l,$created_r,$str_r,$address)=$check_data->fetchrow() ) {
    if(($created_l) && ($str_l)) {push @log_line, "<p>$created_l</p><p>$str_l</p>";}
    if(($created_r) && ($str_r)) {push @log_line, "<p>$created_r</p><p>$str_r</p>";}
}
$check_data->finish;

} else {
    @log_line = ();
}

print<<HTML;
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ru" lang="ru">
<head>
<title>Проверялка</title>
</head>

<style>
.log_consol         { font-family: Roboto Condensed, myriadpro, Arial; }
.search-block       { display: flex; position: relative; opacity: 1; visibility: visible; top: 30px !important; align-items: center; transition: all .2s ease-in-out; bottom: 50px; right: 0; background: #fff; width: 100%; }
.search-block form  { display: block; position: relative; width: 100%; max-width: 600px; padding: 0 50px 0 50px; margin: auto; }
.search-input-div   { position: relative; display: block; padding-right: 0px; width: 100%; }
.search-input       { padding: 0 0px 0 15px; height: 48px; line-height: 48px; font-size: 14px; transition: background .2s ease-in-out; background-color: #fafafa; border: 1px solid #ececec; border-radius: 3px; color: initial; display: block; width: 100%; outline: 0; }
.search-button-div  { position: absolute; top: 0; right: 30px; width: 20%; }
.btn                { background-color: #2da37a; border-color: #257c5e; color: #ffffff; font-size: 0.8rem; font-weight: bold; width: 100%; height: 50px; line-height: 50px; text-transform: uppercase; margin: 0; border: 1px solid; letter-spacing: .8px; border-radius: 3px; position: relative; display: inline-block; text-align: center; vertical-align: middle; cursor: pointer; white-space: nowrap; user-select: none; outline: 0; }
.log_consol         { display: grid;width: calc(100% - 50px);grid-template-rows: repeat(1, 1fr);grid-column-gap: 0px;grid-row-gap: 0px;font-size: 1.0rem;grid-template-columns: 200px auto;margin: 0px auto; }
.count              { display: block;position: relative;width: calc(100% - 50px);margin: 50px auto 0px auto;font-size: 0.9rem;line-height: 2rem;font-weight: 600;border-bottom: 1px solid #d7d7d7; }
</style>

<body>

<div class="search-block">
    <form action="search.pl" method="POST">
        <div class="search-input-div">
            <input class="search-input" id="title-search-input" type="text" name="email" value="$email" placeholder="Поиск" size="20" maxlength="50" autocomplete="off">
        </div>
        <div class="search-button-div">
            <button class="btn" type="submit" value="Найти">Найти</button>
        </div>
    </form>
</div>
<div class="count">Всего записей: $all</div>
<div class="log_consol">
    @log_line
</div>
</body>
</html>
HTML

$dbh -> disconnect;

1;