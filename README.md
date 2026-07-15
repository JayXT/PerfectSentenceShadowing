# PerfectSentenceShadowing

## EN

An mpv script for [perfect sentence shadowing](https://t.me/RefoldUA/184) (Refold Stage 3 → B: Pronunciation Training), aka, [chorusing](https://refold.la/roadmap/library/chorusing) : loop a sentence in content you are watching, pronounce it into your microphone, and compare your take against the original — including a "flow-verlapping" overlay where pronunciation mismatches produce audible dissonance. The goal is to try to get as close to original pronunciation as currently possible. Everything happens inside mpv with single keypresses.

### Requirements

mpv and ffmpeg (on PATH; the macOS version also finds Homebrew packages).

### Install

Copy the file for your platform into the mpv scripts directory (`~/.config/mpv/scripts/` on Linux and macOS, `%APPDATA%\mpv\scripts\` on Windows) — install exactly one:

- `perfect-sentence-shadowing.lua` — GNU/Linux (PulseAudio/PipeWire)
- `perfect-sentence-shadowing-macos.lua` — macOS (default input device; the
  OS asks for microphone permission once)
- `perfect-sentence-shadowing-windows.lua` — Windows (first DirectShow
  capture device, detected automatically on the first recording; for a
  specific device, run `ffmpeg -list_devices true -f dshow -i dummy` and set
  the `local mic` line to `local mic = {"-f", "dshow", "-i", "audio=DEVICE NAME"}` for your microphone)

For the most problem-free experience it's recommended to use GNU/Linux.

### Usage

1. Press `l` at the start of a sentence and `l` again at its end — mpv loops it and the audio clip is extracted automatically. Listen as many times as you like.
2. Press `Alt+r`, imitate the sentence, press `Alt+r` again. Playback pauses while you record; after saving, your take and the original play back to back.
3. Re-record with `Alt+r` until satisfied, then press `Alt+n` to move on.

| Key     | Action                                                    |
| ------- | --------------------------------------------------------- |
| `l` `l` | Set A-B loop and extract the sentence (mpv built-in loop) |
| `Alt+r` | Start/stop recording your imitation                       |
| `Alt+o` | Play the original sentence                                |
| `Alt+m` | Play your recording                                       |
| `Alt+c` | Play your recording, then the original                    |
| `Alt+b` | Play both overlaid — mistakes create dissonance           |
| `Alt+n` | Done with this sentence: clear loop, delete created files, resume |

Clearing the loop with a third `l` press also deletes the working files, so keep the loop set until you are finished with the sentence.

### Notes

- Working files live in `/tmp` and are deleted when the loop is cleared.

## UK

Скрипт для mpv для [ідеального наслідування речень](https://telegra.ph/S3B3-Trenuvannya-vimovi-10-16) (Refold, Стадія 3 → Б: Тренування вимови), також відомого як [хорове повторення](https://refold.la/roadmap/library/chorusing): створіть цикл з реченням у контенті, який дивитеся, вимовте його у свій мікрофон і порівнюйте власну спробу з оригіналом — включно з накладанням у стилі «flow-verlapping», де розбіжності у вимові створюють відчутний дисонанс. Мета — спробувати максимально наблизитися до оригінальної вимови. Усе відбувається всередині mpv одиничними натисканнями клавіш.

### Вимоги

mpv та ffmpeg (доступні через PATH; версія для macOS також знаходить пакети з Homebrew).

### Встановлення

Скопіюйте файл для вашої платформи до каталогу скриптів mpv (`~/.config/mpv/scripts/` на Linux і macOS, `%APPDATA%\mpv\scripts\` на Windows) — встановіть рівно один:

- `perfect-sentence-shadowing.lua` — GNU/Linux (PulseAudio/PipeWire)
- `perfect-sentence-shadowing-macos.lua` — macOS (пристрій введення за
  замовчуванням; ОС одноразово запитає дозвіл на використання мікрофона)
- `perfect-sentence-shadowing-windows.lua` — Windows (перший пристрій
  захоплення DirectShow, який визначається автоматично під час першого
  запису; щоб вибрати конкретний пристрій, виконайте
  `ffmpeg -list_devices true -f dshow -i dummy` і вкажіть у рядку `local mic`
  значення `local mic = {"-f", "dshow", "-i", "audio=НАЗВА ПРИСТРОЮ"}` для вашого мікрофону)

Для найбільш безпроблемного досвіду рекомендовано використовувати GNU/Linux.

### Використання

1. Натисніть `l` на початку речення і ще раз `l` у його кінці — mpv замкне його у повторюваний цикл, а аудіо-кліп буде видобуто автоматично. Слухайте скільки завгодно разів.
2. Натисніть `Alt+r`, повторіть речення, натисніть `Alt+r` ще раз. Під час запису відтворення ставиться на паузу; після збереження ваш запис і оригінал відтворюються один за одним.
3. Перезаписуйте через `Alt+r`, доки не будете задоволені, потім натисніть `Alt+n`, щоб рухатися далі.

| Клавіша | Дія                                                            |
| ------- | -------------------------------------------------------------- |
| `l` `l` | Встановити цикл A-B і витягнути речення (вбудований цикл mpv)   |
| `Alt+r` | Почати/зупинити запис вашої імітації                           |
| `Alt+o` | Відтворити оригінальне речення                                 |
| `Alt+m` | Відтворити ваш запис                                           |
| `Alt+c` | Відтворити ваш запис, потім оригінал                           |
| `Alt+b` | Відтворити обидва накладеними — помилки створюють дисонанс     |
| `Alt+n` | Завершити речення: скинути цикл, видалити створені файли, продовжити    |

Скидання циклу третім натисканням `l` також видаляє робочі файли, тож тримайте цикл встановленим, доки не завершите роботу з реченням.

### Примітки

- Робочі файли зберігаються в `/tmp` і видаляються після скидання циклу.
