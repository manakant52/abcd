import time
import os
import sys
from pynput import mouse
import mysql.connector
from mysql.connector import Error
import re

class MorseDecoder:
    def __init__(self):
        self.letter_delay = 1.0
        self.word_delay = 2.0
        
        self.sequence = []   
        self.last_time = 0
        self.output = ""
        self.pressed = False
        self.current_morse = ""  
        
        self.db_config = {
            'host': 'localhost',
            'user': 'root',
            'password': 'Md7CmUDG',  
            'database': 'pashtets'    
        }
        self.connection = None
        
        self.forbidden_commands = [
            'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER', 
            'TRUNCATE', 'REPLACE', 'GRANT', 'REVOKE', 'FLUSH',
            'RENAME', 'LOAD', 'CALL', 'EXEC', 'EXECUTE',
            'INTO OUTFILE', 'INTO DUMPFILE'
        ]
        
        self.morse_dict = {
            '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
            '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
            '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
            '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
            '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
            '--..': 'Z', '-----': '0', '.----': '1', '..---': '2',
            '...--': '3', '....-': '4', '.....': '5', '-....': '6',
            '--...': '7', '---..': '8', '----.': '9',
            '.-.-.-': '.', '--..--': ',', '-.-.--': '!', '..--..': '?',
            '.----.': "'", '-..-.': '/', '-.--.-': '(', '-.--.-': ')',
            '.-...': '&', '---...': ':', '-.-.-.': ';', '-...-': '=',
            '.-.-.': '+', '-....-': '-', '..--.-': '_', '...-..-': '$',
            '.--.-.': '@', '.-..-': '*'
        }
        
        self.enter_codes = {
            '.-.-': '[ENTER]',      
            '-.-.-': '[STOP]',      
        }

    def connect_to_database(self):
        try:
            self.connection = mysql.connector.connect(**self.db_config)
            if self.connection.is_connected():
                print("Успешно подключено к MySQL базе данных (READ-ONLY режим)")
                db_info = self.connection.get_server_info()
                print(f"Версия сервера MySQL: {db_info}")
                cursor = self.connection.cursor()
                cursor.execute("SELECT DATABASE();")
                record = cursor.fetchone()
                print(f"Подключено к базе данных: {record[0]}")
                cursor.close()
                return True
        except Error as e:
            print(f"Ошибка подключения к MySQL: {e}")
            return False

    def is_safe_query(self, query):
        query_upper = query.upper()
        
        for forbidden in self.forbidden_commands:
            pattern = r'\b' + forbidden.replace(' ', r'\s+') + r'\b'
            if re.search(pattern, query_upper):
                return False, forbidden
        
        if '--' in query or '/*' in query or '*/' in query:
            if '--' in query and not query.strip().endswith('--'):
                return False, "комментарии в середине запроса"
        
        if ';' in query:
            semicolon_count = query.count(';')
            if semicolon_count > 1 or (semicolon_count == 1 and not query.strip().endswith(';')):
                return False, "множественные запросы"
        
        return True, None

    def execute_query(self, query):
        """Выполнение SQL запроса с проверкой безопасности"""
        if not self.connection or not self.connection.is_connected():
            print("\nНет подключения к базе данных!")
            return
        
        # Проверяем безопасность запроса
        is_safe, reason = self.is_safe_query(query)
        if not is_safe:
            print(f"\nЗАПРОС ЗАБЛОКИРОВАН!")
            print(f"Обнаружена попытка изменения данных")
            return
        
        try:
            cursor = self.connection.cursor()
            cursor.execute(query)
            
            results = cursor.fetchall()
            print(f"\nРезультаты запроса ({len(results)} строк):")
            print("-" * 80)
            
            if cursor.description:
                columns = [desc[0] for desc in cursor.description]
                print(" | ".join(f"{col:^15}" for col in columns))
                print("-" * 80)
                
                for row in results:
                    formatted_row = []
                    for val in row:
                        if val is None:
                            formatted_row.append("NULL")
                        else:
                            str_val = str(val)
                            if len(str_val) > 15:
                                str_val = str_val[:12] + "..."
                            formatted_row.append(str_val)
                    print(" | ".join(f"{val:^15}" for val in formatted_row))
                print("-" * 80)
            else:
                print("")
            
            cursor.close()
            
        except Error as e:
            print(f"\nОшибка выполнения запроса: {e}")

    def execute_vulnerable_search(self, name):
        """УЯЗВИМЫЙ поиск владельца по имени - БЕЗ защиты от SQL инъекций!"""
        # ВНИМАНИЕ: Этот код намеренно уязвим для CTF задания!
        # НЕ используйте такой подход в реальных приложениях!
        
        # Строим уязвимый запрос - просто вставляем ввод пользователя напрямую
        vulnerable_query = f"SELECT id, full_name, phone, email FROM owners WHERE full_name = '{name}'"
        
        print(f"\n🔍 Поиск владельца: {name}")
        print(f"📝 Выполняемый запрос: {vulnerable_query}")
        
        # Выполняем уязвимый запрос
        self.execute_query(vulnerable_query)

    def clear_console(self):
        os.system('cls' if os.name == 'nt' else 'clear')

    def update_display(self):
        sys.stdout.write('\r' + ' ' * 120 + '\r')
        display_text = f"Ввод имени владельца: {self.current_morse}"
        if self.output:
            display_text += f"  |  Имя: {self.output}"
        sys.stdout.write(display_text)
        sys.stdout.flush()

    def process_sequence(self):
        morse = ''.join(self.sequence)
        
        if morse in self.enter_codes:
            print(f"\n\n{self.enter_codes[morse]} command received!")
            
            if self.output.strip():
                # Выполняем уязвимый поиск по имени владельца
                self.execute_vulnerable_search(self.output)
            else:
                print("Введите имя владельца для поиска!")
            
            print("\nНачинаем новый поиск...\n")
            self.output = ""
            self.sequence = []
            self.current_morse = ""
            time.sleep(5)  
            self.clear_console()
            self.show_start_message()
            return
        
        letter = self.morse_dict.get(morse, '?')
        self.output += letter
        self.current_morse = ""  
        self.sequence = []
        self.update_display()

    def on_click(self, x, y, button, pressed):
        current_time = time.time()
        time_since_last = current_time - self.last_time
        
        if not pressed:
            self.pressed = False
            if self.sequence:
                self.last_time = current_time
            return
        
        if self.pressed:
            return
        
        self.pressed = True
        
        if self.sequence and time_since_last > self.word_delay:
            self.process_sequence()
            self.output += " "
            self.update_display()
        elif self.sequence and time_since_last > self.letter_delay:
            self.process_sequence()
        
        # Добавление точки или тире
        if button == mouse.Button.left:
            self.sequence.append('.')
            self.current_morse += '.'
        elif button == mouse.Button.right:
            self.sequence.append('-')
            self.current_morse += '-'
        
        self.update_display()
        self.last_time = current_time

    def show_start_message(self):
        print("="*80)
        print("      🔓 УЯЗВИМАЯ СИСТЕМА ПОИСКА ВЛАДЕЛЬЦЕВ СКВАЖИН 🔓")
        print("="*80)
        print("\n🔌 Подключение к MySQL...")
        
        # Пытаемся подключиться к БД
        if not self.connect_to_database():
            print("\n  ВНИМАНИЕ: Работаем без подключения к БД!")
            print("Проверьте настройки подключения в коде.")
        
        print("\n" + "="*80)
        print("\nИзвестные владельцы для тестирования:")
        print("   - MAXIM SMIRNOV")
        print("="*80)
        print("\nИнструкции:")
        print("\nТайминги:")
        print("\nКоманды:")
        print("  .-.-     = [ENTER] - выполнить поиск")
        print("  -.-.-    = [STOP] - выполнить и остановить")
        print("\nАЛФАВИТ МОРЗЕ:")
        print("="*80)
        print("Буквы:")
        print("  A: .-      B: -...    C: -.-.    D: -..")
        print("  E: .       F: ..-.")
        print("  G: --.     H: ....    I: ..      J: .---") 
        print("  K: -.-     L: .-..")
        print("  M: --      N: -.      O: ---     P: .--.")
        print("  Q: --.-    R: .-.") 
        print("  S: ...     T: -       U: ..-     V: ...-")
        print("  W: .--     X: -..-")
        print("  Y: -.--    Z: --..")
        print("\nЦифры:")
        print("  0: -----   1: .----   2: ..---   3: ...--   4: ....-")
        print("  5: .....   6: -....   7: --...   8: ---..   9: ----.")
        print("\nСПЕЦИАЛЬНЫЕ СИМВОЛЫ ДЛЯ SQL ИНЪЕКЦИЙ:")
        print("="*80)
        print("  .  (точка)      : .-.-.-     '  (апостроф)   : .----.")
        print("  ,  (запятая)    : --..--     -  (дефис)      : -....-")
        print("  ;  (точка с зап): -.-.-.     =  (равно)      : -...-")
        print("  (  (скобка)     : -.--.-     )  (скобка)     : -.--.-")
        print("  *  (звездочка)  : .-..-      /  (слэш)       : -..-.")
        print("  +  (плюс)       : .-.-.      _  (подчерк.)   : ..--.-")
        print("  :  (двоеточие)  : ---...     @  (собака)     : .--.-.")
        print("  &  (амперсанд)  : .-...      $  (доллар)     : ...-..-")
        print("  !  (восклиц.)   : -.-.--     ?  (вопрос)     : ..--..")
        print("="*80)
        print("\n🚀 Начните ввод имени владельца или SQL инъекции:")
        print()  
        self.update_display()

    def start(self):
        self.clear_console()
        self.show_start_message()
        
        with mouse.Listener(on_click=self.on_click) as listener:
            try:
                listener.join()
            except KeyboardInterrupt:
                pass
            finally:
                if self.sequence:
                    self.process_sequence()
                print(f"\n\nПоследний поиск: {self.output}")
                
                if self.connection and self.connection.is_connected():
                    self.connection.close()
                    print("MySQL соединение закрыто")

if __name__ == "__main__":
    decoder = MorseDecoder()
    decoder.start()
