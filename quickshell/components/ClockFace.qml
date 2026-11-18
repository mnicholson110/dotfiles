import QtQuick

Canvas {
    id: face
    required property date time
    property color ink: "#ecf3f1"
    property color accent: "#89dac4"
    property color ticks: "#627378"

    onTimeChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.translate(width / 2, height / 2);
        const unit = Math.min(width, height) / 100;
        ctx.scale(unit, unit);
        ctx.lineCap = "round";
        function stroke(angle, inner, outer, weight, color) {
            const x = Math.sin(angle);
            const y = -Math.cos(angle);
            ctx.beginPath();
            ctx.moveTo(inner * x, inner * y);
            ctx.lineTo(outer * x, outer * y);
            ctx.strokeStyle = color;
            ctx.lineWidth = weight;
            ctx.stroke();
        }
        for (let i = 0; i < 60; ++i) {
            const hour = i % 5 === 0;
            if (hour || face.width >= 100)
                stroke(i * Math.PI / 30, hour ? 38 : 43, 46, hour ? 2.6 : 1, hour ? ink : ticks);
        }
        const minutes = time.getMinutes();
        stroke((time.getHours() + minutes / 60) * Math.PI / 6, -3, 23, 5, ink);
        stroke(minutes * Math.PI / 30, -6, 34, 3, accent);
    }
}
