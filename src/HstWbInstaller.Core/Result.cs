namespace HstWbInstaller.Core
{
    using System;

    public class Result
    {
        public enum ResultState : byte
        {
            Faulted,
            Success
        }

        private readonly ResultState State;
        public readonly Error Error;

        public Result()
        {
            State = ResultState.Success;
            Error = null;
        }

        public Result(Error error)
        {
            State = ResultState.Faulted;
            Error = error ?? throw new ArgumentNullException(nameof(error));
        }

        public bool IsSuccess =>
            State == ResultState.Success;

        public bool IsFaulted =>
            State == ResultState.Faulted;
    }

    public class Result<T> : Result
    {
        public readonly T Value;

        public Result(T value)
        {
            Value = value;
        }

        public Result(Error error)
            : base(error)
        {
            Value = default;
        }
    }
}