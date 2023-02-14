#!/usr/bin/perl -i
use strict;
use warnings;

# Путь к логу
my $log='out';

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

# Задаем кодировку и локальное время
#####################################
$dbh->do("SET NAMES utf8");
$dbh->do("SET \@\@lc_time_names='ru_RU'");

# Открываем лог-файл
#####################################
open (FH, $log) || die print 'Не могу открыть файл! \n';
while (<FH>) {
    chomp;
    my @fields=split(' ');
    my $date_line = $fields[0]." ".$fields[1];  # Дата и время
    my $key_id = $fields[2];                    # Внутренний id сообщения
    my $mail;                                   # адрес получателя
    my $mess_id;                                # значение поля id=xxxx из строки лога
    my $line = $_;
    $line =~ s/$fields[0] $fields[1]//g;        # Строка лога (без временной метки)

    # Проверяем на существование и наличе атрибута (id=) в строке
    if (($fields[9]) && ($fields[9] =~ /id\=(.*)/)){$mess_id = $1;} else {$mess_id='';}
    # Проверяем на валидность email
    if (($fields[4]) && ($fields[4] =~ /^[a-z0-9]([a-z0-9.]+[a-z0-9])?\@[a-z0-9.-]+$/)) {$mail = $fields[4];} else {$mail = '';}

    if ($fields[3] eq '<=' && $mess_id){        
        
        # Добавляем в таблицу message только строки прибытия сообщения
        my $insert_data_01 = $dbh->prepare("INSERT INTO `message` (`created`,`id`,`int_id`,`str`) VALUES ('$date_line','$mess_id','$key_id','$line')") or die $dbh->errstr;
        $insert_data_01->execute();
        $insert_data_01->finish();
        $dbh->commit or die $DBI::errstr;
        # print "+ $date_line\t$mess_id\t$key_id\t$line\n";

    } else {                                    
        
        # Добавляем в таблицу log все остальные строки
        my $insert_data_02 = $dbh->prepare("INSERT INTO `log` (`created`,`int_id`,`str`,`address`) VALUES ('$date_line', '$key_id', '$line', '$mail')") or die $dbh->errstr;
        $insert_data_02->execute();
        $insert_data_02->finish();
        $dbh->commit or die $DBI::errstr;
        # print "- $date_line\t$mess_id\t$line\t|$mail|\n";
    }
}
close(FH);


$dbh -> disconnect;

1;