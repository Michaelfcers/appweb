import 'package:flutter/material.dart';
import '../../styles/colors.dart';

class PoliticasScreen extends StatelessWidget {
  const PoliticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Políticas de Uso",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Políticas de Uso de BookSwap",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    """
Bienvenido a BookSwap, tu plataforma de trueque de libros favorita. Al usar nuestra aplicación, aceptas los siguientes términos y condiciones:

1. **Intercambio Responsable**: Asegúrate de que los libros que intercambias estén en buen estado y sean apropiados para los usuarios de la comunidad.

2. **Respeto a los Usuarios**: Mantén siempre una comunicación respetuosa y amigable con otros miembros de la comunidad.

3. **Uso Personal**: BookSwap está diseñado para uso personal. No está permitido utilizar la plataforma para fines comerciales.

4. **Propiedad Intelectual**: No subas contenido que infrinja derechos de autor o propiedad intelectual.

5. **Privacidad**: La información compartida con otros usuarios debe ser tratada con confidencialidad y no puede ser utilizada fuera de la plataforma.

6. **Prohibición de Contenido Inadecuado**: Está estrictamente prohibido publicar contenido ofensivo, discriminatorio o ilegal.

Al usar esta plataforma, aceptas cumplir con estas políticas. Nos reservamos el derecho de suspender o eliminar cuentas que violen nuestras normas.

Si tienes alguna pregunta o inquietud, no dudes en contactarnos a través de nuestra sección de ayuda.
                    """,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
