import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '20s', target: 5 },   // Montée à 5 utilisateurs
    { duration: '5m', target: 15 },   // Vitesse de croisière
    { duration: '20s', target: 0 },   // Arrêt
  ],
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  // 1. Appel vers la route extraite /vets
  let resVets = http.get(`${BASE_URL}/vets`, {
    headers: { 'Accept': 'application/json' },
  });
  check(resVets, {
    'vets status is 200': (r) => r.status === 200,
    'vets latency < 100ms': (r) => r.timings.duration < 100,
  });

  // 2. Appel vers le monolithe (navigation générale)
  let resHome = http.get(`${BASE_URL}/`);
  check(resHome, {
    'home status is 200': (r) => r.status === 200,
  });

  sleep(0.2);
}
