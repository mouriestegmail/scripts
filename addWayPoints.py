import gpxpy
import gpxpy.gpx
from geopy.distance import geodesic


file = "/home/andreysokolov/Downloads/gpx/SVT-27K"
file_out = file + "_waypoint.gpx"
file = file + ".gpx"
# Чтение GPX
with open(file, "r", encoding="utf-8") as f:
    gpx = gpxpy.parse(f)

# Подготовка
distance_total = 0
distance_next_wpt = 1000  # следующий километр
wpt_counter = 1
prev_point = None
new_waypoints = []

def interpolate_point(p1, p2, fraction):
    lat = p1.latitude + (p2.latitude - p1.latitude) * fraction
    lon = p1.longitude + (p2.longitude - p1.longitude) * fraction
    ele = None
    if p1.elevation is not None and p2.elevation is not None:
        ele = p1.elevation + (p2.elevation - p1.elevation) * fraction
    return lat, lon, ele

def is_near_existing_waypoint(km_point_coord, original_waypoints, threshold=100):
    """Check if a km_point_coord is within `threshold` meters of any original waypoint"""
    for wp in original_waypoints:
        dist = geodesic(km_point_coord, (wp.latitude, wp.longitude)).meters
        if dist < threshold:
            return True
    return False
# ...

for track in gpx.tracks:
    for segment in track.segments:
        for point in segment.points:
            if prev_point:
                d = geodesic(
                    (prev_point.latitude, prev_point.longitude),
                    (point.latitude, point.longitude)
                ).meters
                distance_total += d

                while distance_total >= distance_next_wpt:
                    overshoot = distance_total - distance_next_wpt
                    fraction = 1 - (overshoot / d)

                    lat, lon, ele = interpolate_point(prev_point, point, fraction)

                    wpt = gpxpy.gpx.GPXWaypoint(
                        latitude=lat,
                        longitude=lon,
                        name=f"{int(ele)}"
                    )
                    if wpt_counter != 0:
                        if not is_near_existing_waypoint((lat, lon), gpx.waypoints, threshold=500):
                            new_waypoints.append(wpt)

                    wpt_counter += 1
                    distance_next_wpt += 1000

            prev_point = point

# Добавляем новые путевые точки
for wpt in new_waypoints:
    gpx.waypoints.append(wpt)

# Сохраняем новый GPX
with open(file_out, "w", encoding="utf-8") as f:
    f.write(gpx.to_xml())
