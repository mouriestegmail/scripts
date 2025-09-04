import re
import os


def parse_time(line):
    match = re.match(r"\|(\d{2}):(\d{2}):(\d{2}\.\d{3})\|", line)
    if match:
        h, m, s = map(float, match.groups())
        return h * 3600 + m * 60 + s  # Время в секундах
    return None


def find_start_pos(file, target_time):
    left, right = 0, os.path.getsize(file)
    with open(file, 'r', encoding='utf-8', errors='ignore') as f:
        while left < right:
            mid = (left + right) // 2
            f.seek(mid)
            f.readline()  # Пропускаем неполную строку
            line = f.readline()

            if not line:
                right = mid
                continue

            ts = parse_time(line)
            if ts is None or ts < target_time:
                left = mid + 1
            else:
                right = mid

        return left


def cut_file(fn, time_start, time_dur, out_fn):
    target_time = sum(x * t for x, t in zip([3600, 60, 1], map(int, time_start.split(':'))))
    time_end = target_time + time_dur

    pos = find_start_pos(fn, target_time)

    with open(fn, 'r', encoding='utf-8', errors='ignore') as f, open(out_fn, 'w', encoding='utf-8') as out:
        f.seek(pos)
        for line in f:
            ts = parse_time(line)
            if ts is None:
                continue
            if ts >= time_end:
                break
            out.write(line)

dirn = '/home/andreysokolov/Documents/logs/CQ_forward/preserve/preserve_clid/tel-02/'
infn = dirn + 'tel_2025-04-23_2.log'
outfn = dirn + 'cut_tel02.log'
cut_file(fn=infn,
         time_start='10:47:00',
         time_dur=40,
         out_fn=outfn
         )


