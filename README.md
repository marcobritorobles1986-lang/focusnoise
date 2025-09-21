## Resumen
Agrega workflow de GitHub Actions para:
- dart format --check
- flutter analyze
- flutter test --coverage
- flutter build apk --release (smoke build)

Añade analysis_options.yaml con lints más estrictos (flutter_lints ^6).
Incluye test mínimo para validar el pipeline.

## Motivación
Garantizar calidad mínima en cada push/PR y evitar regresiones tempranas.

## Checklist
- [ ] CI pasa en verde
- [ ] `flutter analyze` sin warnings críticos
- [ ] Tests mínimos incluidos
